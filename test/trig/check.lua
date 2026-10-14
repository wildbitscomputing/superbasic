-- Headless MAME smoke-test driver. MAME_TEST names the BASIC file;
-- MAME_EXPECT is its success message. The caller must check RESULT: PASS.
local machine = manager.machine
local textmem
for tag, device in pairs(machine.devices) do
    if string.find(tag, 'iopage2') then
        for name, index in pairs(device.items) do
            if string.find(name, 'm_pointer') then textmem = emu.item(index) end
        end
    end
end
assert(textmem, 'Cannot find text video memory')
local frame = 0
local runFrame
emu.register_frame_done(function()
    frame = frame + 1
    if frame == 180 then
        machine.natkeyboard:post('load "' .. (os.getenv('MAME_TEST') or 'TEST.BAS') .. '"\n')
    end
    if frame < 240 or frame % 60 ~= 0 then return end
    local rows = {}
    for row = 0, 59 do
        local chars = {}
        for col = 0, 79 do
            local b = textmem:read(row * 80 + col)
            chars[#chars + 1] = (b >= 32 and b < 127) and string.char(b) or ' '
        end
        rows[#rows + 1] = table.concat(chars)
    end
    local screen = table.concat(rows, '\n')
    if not runFrame then
        if string.find(screen, 'Complete.', 1, true) then
            runFrame = frame
            machine.natkeyboard:post('run\n')
        end
        return
    end
    local passed = string.find(screen, os.getenv('MAME_EXPECT') or 'TRIG PASS', 1, true)
    local failed = string.find(screen, ' at line ', 1, true)
        or string.find(screen, 'UNEXPECTED SUCCESS', 1, true)
    if passed or failed then
        print(screen)
        print('RUN_FRAMES: ' .. (frame - runFrame))
        print(passed and 'RESULT: PASS' or 'RESULT: FAIL')
        machine:exit()
    end
end)
