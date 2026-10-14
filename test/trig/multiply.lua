-- Direct machine-code regression for TrigFixedMultiply. This takes over a
-- disposable emulator after boot; no BASIC parser/float rounding is involved.
-- Run with run-mame.py --case MULTIPLY (labels must match the ROM build).
local machine = manager.machine
local cpu = machine.devices[':maincpu']
local mem = cpu.spaces['program']
local labels = {}
for line in io.lines(assert(os.getenv('MAME_LABELS'))) do
    local name, address = line:match('^(%w+)%s*=%s*%$(%x+)')
    if name then labels[name] = tonumber(address, 16) end
end
local function address(name) return assert(labels[name], 'Missing label: '..name) end
local function write(addr, value, bytes)
    for i=0,bytes-1 do mem:write_u8(addr+i, (value >> (8*i)) & 255) end
end
local function read(addr, bytes)
    local result = 0
    for i=0,bytes-1 do result = result | (mem:read_u8(addr+i) << (8*i)) end
    return result
end
local vectors = {}
local values = {0, 1, 65535, 65536, 65537, 0x1fffffff, 0x20000000,
                0x20000001, 0x3fffffff, 0x40000000}
local deltas = {0, 1, 2, 65535, 65536, 65537, 13176794, 13176795}
for _, a in ipairs(values) do
    for _, b in ipairs(deltas) do
        for _, sa in ipairs({1, -1}) do
            for _, sb in ipairs({1, -1}) do
                vectors[#vectors+1] = {sa*a, sb*b}
            end
        end
    end
end
local seed = 6502
local function random(limit)
    seed = (seed*1664525 + 1013904223) & 0xffffffff
    return seed % limit
end
for i=1,4096 do
    vectors[#vectors+1] = {random(0x80000001)-0x40000000,
                           random(26353591)-13176795}
end
local frame, current = 0, 0
local expected, ioPage, interruptFlag
local preserved = {{'trigAngle', 4}, {'trigIndex', 1}, {'trigSign', 1}, {'trigCosSign', 1}}
local function check()
    assert(mem:read_u8(0x2100) == 1, string.format(
        'Vector %d did not return: PC=%X bank=%X target=%X first=%X',
        current, cpu.state['PC'].value, mem:read_u8(0x0b), address('TrigFixedMultiply'),
        mem:read_u8(address('TrigFixedMultiply'))))
    local got = read(address('trigWork'), 4)
    assert(got == (expected & 0xffffffff), string.format(
        'Vector %d: %d * %d: got %08X expected %08X', current,
        vectors[current][1], vectors[current][2], got, expected & 0xffffffff))
    assert((mem:read_u8(0x2101) & 4) == interruptFlag, 'Interrupt flag changed')
    assert(mem:read_u8(0x2102) == 0x5a, 'X changed')
    assert(mem:read_u8(0x2103) == ioPage, 'I/O mapping changed')
    assert(mem:read_u8(0x2104) == mem:read_u8(0x2105), 'Stack unbalanced')
    assert(read(address('trigDelta'), 3) == math.abs(vectors[current][2]), 'Delta changed')
    assert(mem:read_u8(address('trigDeltaSign')) ==
           (vectors[current][2] < 0 and 128 or 0), 'Delta sign changed')
    for i, item in ipairs(preserved) do
        for byte=0,item[2]-1 do
            assert(mem:read_u8(address(item[1])+byte) == i*17+byte, item[1]..' changed')
        end
    end
    mem:write_u8(1, 0)
    assert(read(0xde00, 4) == 0x56781234, 'Multiplier operands changed')
    assert(read(0xde10, 4) == 0x1234*0x5678, 'Multiplier result changed')
end
local function launch()
    local a, b = table.unpack(vectors[current])
    expected = (math.abs(a)*math.abs(b) + 0x20000000) >> 30
    if (a < 0) ~= (b < 0) then expected = -expected end
    ioPage = (current-1) % 8 -- all four I/O pages, plus I/O disabled
    interruptFlag = ((current-1) // 8) % 2 == 0 and 4 or 0
    write(address('trigWork'), a, 4)
    write(address('trigDelta'), math.abs(b), 3)
    mem:write_u8(address('trigDeltaSign'), b < 0 and 128 or 0)
    for i, item in ipairs(preserved) do
        for byte=0,item[2]-1 do mem:write_u8(address(item[1])+byte, i*17+byte) end
    end
    mem:write_u8(1, 0)
    -- This MAME driver raises SOF even when masked. Clear the pending frame
    -- interrupt immediately before the short test call (well under a frame).
    for i=0,2 do mem:write_u8(0xd660+i, 255) end
    cpu.state['IRQ'].value = 0
    write(0xde00, 0x56781234, 4)
    local target = address('TrigFixedMultiply')
    local code = {
        0xd8,                         -- CLD
        0xba, 0x8e, 0x05, 0x21,      -- TSX / STX $2105 (initial SP)
        0xa2, 0x5a,                  -- LDX #$5a
        0xa9, ioPage, 0x85, 0x01,    -- LDA #page / STA $01
        interruptFlag == 0 and 0x58 or 0x78, -- CLI / SEI
        0x20, target & 255, target >> 8, -- JSR TrigFixedMultiply
        0x08, 0x78, 0x68,            -- PHP / SEI / PLA
        0x8d, 0x01, 0x21,            -- STA $2101 (returned flags)
        0x8e, 0x02, 0x21,            -- STX $2102
        0xa5, 0x01, 0x8d, 0x03, 0x21, -- LDA $01 / STA $2103
        0xba, 0x8e, 0x04, 0x21,      -- TSX / STX $2104
        0xee, 0x00, 0x21,            -- INC $2100 (completion)
        0x80, 0xfe,                  -- BRA *
    }
    for i, byte in ipairs(code) do mem:write_u8(0x2000+i-1, byte) end
    mem:write_u8(0x2100, 0)
    cpu.state['GENPC'].value = 0x2000
end
emu.register_frame_done(function()
    frame = frame + 1
    -- Let firmware startup finish before installing code in BASIC RAM.
    if frame < 300 then return end
    if frame == 300 then
        -- Enter through BASIC so the CPU is not suspended in the kernel's
        -- WAI instruction when we start redirecting its program counter.
        local boot = {0x78, 0xee, 0x00, 0x21, 0x80, 0xfe} -- SEI / INC / BRA *
        for i, byte in ipairs(boot) do mem:write_u8(0x2000+i-1, byte) end
        mem:write_u8(0x2100, 0)
        machine.natkeyboard:post('call $2000\n')
        return
    end
    if current == 0 and mem:read_u8(0x2100) == 0 then
        if frame == 600 then
            print(string.format('RESULT: FAIL: bootstrap timeout PC=%X code=%X',
                cpu.state['PC'].value, mem:read_u8(0x2000)))
            for tag, device in pairs(machine.devices) do
                if tag:find('iopage2') then
                    for name, index in pairs(device.items) do
                        if name:find('m_pointer') then
                            local screen, chars = emu.item(index), {}
                            for p=0,4799 do
                                local b = screen:read(p)
                                chars[#chars+1] = b >= 32 and b < 127 and string.char(b) or ' '
                            end
                            print(table.concat(chars))
                        end
                    end
                end
            end
            machine:exit()
        end
        return
    end
    local ok, failure = pcall(function()
        if current == 0 then
            -- Take ownership at a known 65C02-compatible CPU boundary,
            -- independent of where the firmware was when the frame ended.
            cpu.state['E'].value = 1
            cpu.state['P'].value = 0x34
            cpu.state['S'].value = 0x1ff
            cpu.state['D'].value = 0
            cpu.state['DB'].value = 0
            cpu.state['PB'].value = 0
            -- Disable hardware IRQ sources so both caller I states can be
            -- checked without an unrelated kernel ISR changing the test.
            mem:write_u8(1, 0)
            for i=0,2 do mem:write_u8(0xd66c+i, 255) end
            for i=0,2 do mem:write_u8(0xd660+i, 255) end
            cpu.state['IRQ'].value = 0
            mem:write_u8(0x0b, mem:read_u8(address('Slot3ModulePage')))
        else
            check()
        end
        current = current + 1
        if current > #vectors then
            print('MULTIPLY PASS: '..#vectors..' exact vectors, I/O, IRQ, X, stack and operands')
            print('RESULT: PASS')
            machine:exit()
        else
            launch()
        end
    end)
    if not ok then
        print('RESULT: FAIL: '..tostring(failure))
        machine:exit()
    end
end)
