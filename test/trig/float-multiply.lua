-- Direct FloatMultiply tests: exact legacy results, zero/unnormalised inputs,
-- exponent boundaries, caller registers, numeric-stack/trig scratch canaries,
-- I/O and multiplier restoration, and both root/nested bank-2 entry.
-- The same vectors also run against the saved pre-acceleration ROM.
local machine = manager.machine
local cpu = machine.devices[':maincpu']
local mem = cpu.spaces['program']
local labels = {}
for line in io.lines(assert(os.getenv('MAME_LABELS'))) do
    local name, value = line:match('^(%w+)%s*=%s*%$(%x+)')
    if name then labels[name] = tonumber(value, 16) end
end
local function address(name) return assert(labels[name], 'Missing label: '..name) end
local function write(addr, value, count)
    for i=0,count-1 do mem:write_u8(addr+i, (value >> (8*i)) & 255) end
end
local function read(addr, count)
    local value = 0
    for i=0,count-1 do value = value | (mem:read_u8(addr+i) << (8*i)) end
    return value
end
local fields = {'NSMantissa0', 'NSMantissa1', 'NSMantissa2', 'NSMantissa3',
                'NSExponent', 'NSStatus'}
local function slot(index, value)
    if value then
        for i, name in ipairs(fields) do mem:write_u8(address(name)+index, value[i]) end
    else
        value = {}
        for i, name in ipairs(fields) do value[i] = mem:read_u8(address(name)+index) end
    end
    return value
end
local function packed(m, e, s)
    return {m & 255, (m >> 8) & 255, (m >> 16) & 255, m >> 24, e & 255, s}
end
local function normalise(m, e)
    if m ~= 0 then
        while m < 0x40000000 do m = m << 1; e = e-1 end
    end
    return m, e & 255
end
local function reference(v)
    local a, b, ae, be, sa, sb = table.unpack(v)
    a, ae = normalise(a, ae)
    -- NSNormalise currently leaves the incoming sign on a zero mantissa.
    -- Preserve that legacy representation too; this is not a numeric rewrite.
    if a == 0 then return packed(0, ae, 8 | sa) end
    if b == 0 then return packed(0, 0, 8) end
    b, be = normalise(b, be)
    local m, e = normalise((a*b) >> 31, ae+be+31)
    return packed(m, e, 8 | (sa ~ sb))
end
local vectors = {}
local edges = {0, 1, 2, 65535, 65536, 65537, 0x3fffffff, 0x40000000,
               0x40000001, 0x4000ffff, 0x55555555, 0x5a827999,
               0x5a82799a, 0x7fff0000, 0x7ffffffe, 0x7fffffff}
for _, a in ipairs(edges) do
    for _, b in ipairs(edges) do
        for _, sa in ipairs({0, 128}) do
            for _, sb in ipairs({0, 128}) do
                vectors[#vectors+1] = {a, b, -30, -30, sa, sb}
            end
        end
    end
end
local exponents = {-128, -127, -97, -31, -30, -1, 0, 1, 63, 126, 127}
for _, ae in ipairs(exponents) do
    for _, be in ipairs(exponents) do
        for _, a in ipairs({0, 1, 0x40000001, 0x7fffffff}) do
            vectors[#vectors+1] = {a, 0x55555555, ae, be, 128, 0}
        end
    end
end
local seed = 65816
local function random(limit)
    seed = (seed*1664525 + 1013904223) & 0xffffffff
    return seed % limit
end
for i=1,4096 do
    vectors[#vectors+1] = {random(0x80000000), random(0x80000000),
        random(256), random(256), (random(256) & 128), (random(256) & 128)}
end
local frame, current, checksum = 0, 0, 0
local index, ioPage, interruptFlag, depth, ramPage, expected, before
local scratchStart = address('trigMode')
local scratchEnd = address('trigScratch')+17
local function check()
    assert(mem:read_u8(0x2100) == 1, 'Vector '..current..' did not return')
    local result = slot(index)
    for i=1,6 do
        assert(result[i] == expected[i], string.format(
            'Vector %d %s: got %02X expected %02X', current, fields[i], result[i], expected[i]))
        checksum = (checksum*33 + result[i]) & 0xffffffff
    end
    assert((mem:read_u8(0x2101) & 4) == interruptFlag, 'I flag changed')
    assert(mem:read_u8(0x2102) == index, 'X changed')
    assert(mem:read_u8(0x2103) == ioPage, 'I/O mapping changed')
    assert(mem:read_u8(0x2104) == mem:read_u8(0x2105), 'Stack unbalanced')
    assert(mem:read_u8(0x2106) == 0xa5, 'A changed')
    assert(mem:read_u8(0x2107) == 0x3c, 'Y changed')
    local bank = depth == 1 and mem:read_u8(address('Slot3ModulePage')) or ramPage
    assert(mem:read_u8(0x0b) == bank, 'Slot 3 mapping changed')
    assert(mem:read_u8(address('Slot3Depth')) == depth, 'Slot 3 depth changed')
    assert(mem:read_u8(address('Slot3Saved')) == ramPage, 'Saved bank changed')
    for n=0,15 do
        if n < index or n > index+2 then
            local got = slot(n)
            for i=1,6 do assert(got[i] == before[n][i], 'Unrelated numeric slot changed') end
        end
    end
    for p=scratchStart,scratchEnd do
        assert(mem:read_u8(p) == ((p-scratchStart)*13+7) % 256, 'Trig scratch changed')
    end
    mem:write_u8(1, 0)
    assert(read(0xde00, 4) == 0x56781234, 'Multiplier operands changed')
    assert(read(0xde10, 4) == 0x1234*0x5678, 'Multiplier result changed')
end
local function launch()
    local v = vectors[current]
    index = (current-1) % 14
    ioPage = (current-1) % 8
    interruptFlag = ((current-1) // 8) % 2 == 0 and 4 or 0
    depth = ((current-1) // 16) % 2
    expected, before = reference(v), {}
    for n=0,15 do before[n] = slot(n, {n+1, n+17, n+33, n+49, n+65, n+81}) end
    slot(index, packed(v[1], v[3], v[5] | 8))
    slot(index+1, packed(v[2], v[4], v[6] | 8))
    for p=scratchStart,scratchEnd do mem:write_u8(p, ((p-scratchStart)*13+7) % 256) end
    mem:write_u8(address('Slot3Depth'), depth)
    mem:write_u8(address('Slot3Saved'), ramPage)
    mem:write_u8(0x0b, depth == 1 and mem:read_u8(address('Slot3ModulePage')) or ramPage)
    mem:write_u8(1, 0)
    -- MAME's SOF interrupt ignores its mask. Clear it before this short call.
    for i=0,2 do mem:write_u8(0xd660+i, 255) end
    cpu.state['IRQ'].value = 0
    write(0xde00, 0x56781234, 4)
    local target = address('FloatMultiply')
    local code = {
        0xd8, 0xba, 0x8e, 0x05, 0x21, -- CLD / TSX / STX $2105
        0xa2, index, 0xa0, 0x3c,       -- LDX #index / LDY #$3c
        0xa9, ioPage, 0x85, 0x01,      -- LDA #page / STA $01
        0xa9, 0xa5,                    -- LDA #$a5
        interruptFlag == 0 and 0x58 or 0x78, -- CLI / SEI
        0x20, target & 255, target >> 8, -- JSR FloatMultiply
        0x8d, 0x06, 0x21,              -- STA $2106 (returned A)
        0x08, 0x78, 0x68,              -- PHP / SEI / PLA
        0x8d, 0x01, 0x21, 0x8e, 0x02, 0x21, -- STA flags / STX
        0x8c, 0x07, 0x21,              -- STY $2107
        0xa5, 0x01, 0x8d, 0x03, 0x21, -- LDA $01 / STA $2103
        0xba, 0x8e, 0x04, 0x21,        -- TSX / STX $2104
        0xee, 0x00, 0x21, 0x80, 0xfe, -- INC completion / BRA *
    }
    for i, byte in ipairs(code) do mem:write_u8(0x2000+i-1, byte) end
    mem:write_u8(0x2100, 0)
    cpu.state['GENPC'].value = 0x2000
end
emu.register_frame_done(function()
    frame = frame + 1
    if frame < 300 then return end
    if frame == 300 then
        -- Enter from BASIC to wake the CPU from any kernel WAI first.
        local boot = {0x78, 0xee, 0x00, 0x21, 0x80, 0xfe}
        for i, byte in ipairs(boot) do mem:write_u8(0x2000+i-1, byte) end
        mem:write_u8(0x2100, 0)
        machine.natkeyboard:post('call $2000\n')
        return
    end
    if current == 0 and mem:read_u8(0x2100) == 0 then
        if frame == 900 then print('RESULT: FAIL: bootstrap timeout'); machine:exit() end
        return
    end
    local ok, failure = pcall(function()
        if current == 0 then
            cpu.state['P'].value = 0x34
            cpu.state['S'].value = 0x1ff
            cpu.state['D'].value = 0
            cpu.state['DB'].value = 0
            cpu.state['PB'].value = 0
            mem:write_u8(1, 0)
            for i=0,2 do mem:write_u8(0xd66c+i, 255) end
            ramPage = mem:read_u8(0x0b)
        else
            check()
        end
        current = current + 1
        if current > #vectors then
            print(string.format('FLOATMUL PASS: %d exact vectors; checksum %08X', #vectors, checksum))
            print('RESULT: PASS')
            machine:exit()
        else
            launch()
        end
    end)
    if not ok then print('RESULT: FAIL: '..tostring(failure)); machine:exit() end
end)
