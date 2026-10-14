-- Headless console regression for banked LIST, edits, FN/PROC and array RAM.
local machine = manager.machine
local cpu = assert(machine.devices[":maincpu"])
local memory = cpu.spaces["program"]
local textmem
for tag, device in pairs(machine.devices) do
    if string.find(tag, 'iopage2') then
        for name, index in pairs(device.items) do
            if string.find(name, 'm_pointer') then textmem = emu.item(index) end
        end
    end
end
assert(textmem)
local function screen()
    local chars = {}
    for i=0,4799 do
        local b=textmem:read(i)
        chars[#chars+1]=(b>=32 and b<127) and string.char(b) or ' '
    end
    return table.concat(chars):lower()
end
local steps = {
    {'new'},
    {'10 pad=alloc(8192):dim a(1):a(0)=30'},
    {'20 if 0'},
    {'30 print "wrong branch"'},
    {'40 else'},
    {'50 print "branch ok"'},
    {'60 endif'},
    {'70 end'},
    {'100 proc demo()'},
    {'110 print "procedure body"'},
    {'120 endproc'},
    {'200 fn twice(x)=x*2'},
    {'210 fn plus(x)'},
    {'220 return x+1'},
    {'230 endfn'},
    {'cls:run'},
    {'cls:list 100,120', 'branch ok'},
    {'cls:list demo()', 'procedure body'},
    {'cls:list twice()', 'procedure body'},
    {'cls:list plus()', 'fn twice'},
    {'cls:list 0+a(0),50', 'endfn'},
    {'cls:print a(0),twice(7),plus(8)', 'wrong branch'},
    {'cls:print "array survived"', '30'},
    {'50 print "edited branch"', 'array survived'},
    {'cls:run'},
    {'cls:list 50', 'edited branch'},
    {'cls:print "list pass"', 'edited branch'},
}
local frame, step = 0, 0
emu.register_frame_done(function()
    frame=frame+1
    if frame<180 or frame%300~=0 then return end
    step=step+1
    local entry=steps[step]
    if entry then
        if entry[2] and not string.find(screen(),entry[2],1,true) then
            print('RESULT: FAIL at step '..step..' expected '..entry[2])
            print(string.format('PC=%04x slot3=%d',cpu.state['PC'].value,memory:read_u8(11)))
            print(screen())
            machine:exit()
            return
        end
        machine.natkeyboard:post(entry[1]..'\n')
    else
        assert(string.find(screen(),'list pass',1,true))
        assert(memory:read_u8(11)==3, 'LIST did not restore slot 3')
        print('RESULT: PASS: LIST ranges, PROC/FN, array RAM, edited RUN')
        machine:exit()
    end
end)
