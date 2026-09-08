-- One spinner for work that runs in the background, rendered by a single
-- lualine component. Nothing here blocks. Git blame and LSP indexing both
-- return immediately and finish later; this only surfaces that they are still
-- running.
--
-- Sources are functions returning a label, or nil when idle. They keep their
-- own detection, so git blame counts callbacks and LSP reads live client
-- state, but they share one timer, one frame counter and one component, so
-- adding a source is a function rather than another copy of the plumbing.
local M = {}

-- weather-moon_alt_* (U+E3C8-E3E3): a full lunar cycle in codepoint order,
-- waxing crescent through to new. Chosen over the other moon sets because
-- every frame measures exactly 1.25 cells wide, so the glyph does not grow
-- and shrink as it cycles.
M.frames = {}
for cp = 0xE3C8, 0xE3E3 do
    M.frames[#M.frames + 1] = vim.fn.nr2char(cp)
end

-- Milliseconds per frame. The timer ticks at this rate and status() picks its
-- frame off the clock at the same rate, so the two have to stay in step.
local FRAME_MS = 80

local sources = {}
local timer = assert(vim.uv.new_timer())

-- Redraw hook, supplied by whichever plugin renders M.status(), currently
-- plugin/lualine.lua, the file that declares lualine. Inverting it this way
-- keeps this module free of any plugin dependency of its own. No-op until then.
local render = function() end

---@param fn fun()
function M.on_refresh(fn)
    render = fn
end

-- Redraw now, for callers that change state between timer ticks.
function M.refresh()
    render()
end

---@param source fun(): string|nil
function M.register(source)
    sources[#sources + 1] = source
end

function M.status()
    local parts = {}
    for _, source in ipairs(sources) do
        local label = source()
        if label then
            parts[#parts + 1] = label
        end
    end
    if #parts == 0 then
        return ''
    end
    local elapsed_frames = math.floor(vim.uv.hrtime() / (FRAME_MS * 1e6))
    local frame = M.frames[(elapsed_frames % #M.frames) + 1]
    return frame .. ' ' .. table.concat(parts, '  ')
end

-- Start animating. Idempotent, and the timer stops itself once every source is
-- idle, so nothing has to track who is still working.
function M.poke()
    if timer:is_active() then
        return
    end
    timer:start(
        0,
        FRAME_MS,
        vim.schedule_wrap(function()
            if M.status() == '' then
                timer:stop()
            end
            render()
        end)
    )
end

return M
