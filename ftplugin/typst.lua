vim.bo.errorformat = table.concat({"%f:%l:%c: %trror: %m", "%f:%l:%c: %tarning: %m", "%-G%.%#"}, ",")
local idle_ms = 10000
local states = {}
local function st(buf)
  local or_1_ = states[buf]
  if not or_1_ then
    local s = {lines = {}, compiled = false, opened = false, typing = false, viewed = false}
    states[buf] = s
    or_1_ = s
  end
  return or_1_
end
local function alive_3f(job)
  return (job and (-1 == vim.fn.jobwait({job}, 0)[1]))
end
local function spawn(cmd, opts)
  local job = vim.fn.jobstart(cmd, opts)
  if (job > 0) then
    return job
  else
    return vim.notify((cmd[1] .. " did not start"), vim.log.levels.ERROR)
  end
end
local function pdf_of(buf)
  return (vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p:r") .. ".pdf")
end
local function set_status()
  return vim.cmd.redrawstatus({bang = true})
end
local function open_viewer(buf, pdf)
  local function _4_()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf]["typst_viewer"] = nil
      return set_status()
    else
      return nil
    end
  end
  vim.b[buf]["typst_viewer"] = spawn({"zathura", pdf}, {on_exit = _4_})
  return set_status()
end
local function absolute(line, cwd)
  local function _6_(path, rest)
    return (cwd .. "/" .. path .. rest)
  end
  return (line:gsub("^([^/][^:]*)(:%d+:%d+: )", _6_))
end
local function show(buf)
  local s = st(buf)
  local efm = vim.bo[buf].errorformat
  local title = ("typst watch " .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:."))
  if (s.compiled and not s.typing) then
    do
      local items = vim.fn.getqflist({lines = s.lines, efm = efm}).items
      local errors
      do
        local n = 0
        for _, e in ipairs(items) do
          if (e.type == "e") then
            n = (n + 1)
          else
            n = n
          end
        end
        errors = n
      end
      local mine = (title == vim.fn.getqflist({title = 0}).title)
      vim.b[buf]["typst_errors"] = errors
      if (mine or (#items > 0)) then
        Utils.set_qf(title, s.lines, efm)
      else
      end
      if ((errors > 0) and not s.opened) then
        s.opened = true
        vim.cmd("botright copen")
        vim.cmd("wincmd p")
      elseif (mine and (0 == #items)) then
        vim.cmd.cclose()
      else
      end
      if ((0 == errors) and not s.viewed and (1 == vim.fn.filereadable(pdf_of(buf)))) then
        s.viewed = true
        open_viewer(buf, pdf_of(buf))
      else
      end
    end
    return set_status()
  else
    return nil
  end
end
local function release(buf)
  local s = st(buf)
  if s.timer then
    s.timer:stop()
  else
  end
  s.typing = false
  return show(buf)
end
local function hold(buf)
  local s = st(buf)
  s.typing = true
  if not s.timer then
    s.timer = vim.uv.new_timer()
  else
  end
  s.timer:stop()
  local function _14_()
    return release(buf)
  end
  return s.timer:start(idle_ms, 0, vim.schedule_wrap(_14_))
end
local function autosave(buf)
  if (vim.b[buf].typst_mode and alive_3f(vim.b[buf].typst_watch) and vim.bo[buf].modified and ("" == vim.bo[buf].buftype) and ("" ~= vim.api.nvim_buf_get_name(buf))) then
    hold(buf)
    vim.b[buf]["typst_autosaving"] = true
    vim.cmd("silent! update")
    vim.b[buf]["typst_autosaving"] = nil
    return nil
  else
    return nil
  end
end
local function start_watch(buf)
  local s = st(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  local cwd = vim.fn.getcwd()
  local pending = ""
  s.viewed = false
  s.typing = false
  local function on_output(_, data)
    data[1] = (pending .. data[1])
    pending = table.remove(data)
    for _0, line in ipairs(data) do
      if line:find("^%[[%d:]+%] compiling") then
        s.lines = {}
        s.compiled = false
        s.opened = false
      elseif line:find("^%[[%d:]+%] compiled") then
        s.compiled = true
      elseif s.compiled then
        table.insert(s.lines, absolute(line, cwd))
      else
      end
    end
    if (s.compiled and vim.api.nvim_buf_is_valid(buf)) then
      return show(buf)
    else
      return nil
    end
  end
  vim.cmd("silent! wall")
  vim.b[buf]["typst_errors"] = 0
  local function _18_()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf]["typst_watch"] = nil
      return set_status()
    else
      return nil
    end
  end
  vim.b[buf]["typst_watch"] = spawn({"typst", "watch", "--diagnostic-format", "short", file}, {on_stderr = on_output, on_exit = _18_})
  return nil
end
local function stop(buf)
  for _, name in ipairs({"typst_watch", "typst_viewer"}) do
    local job = vim.b[buf][name]
    if job then
      vim.fn.jobstop(job)
    else
    end
  end
  return nil
end
local function toggle()
  local buf = vim.api.nvim_get_current_buf()
  local watch = alive_3f(vim.b.typst_watch)
  local viewer = alive_3f(vim.b.typst_viewer)
  if (watch and viewer) then
    return stop(buf)
  elseif watch then
    if (1 == vim.fn.filereadable(pdf_of(buf))) then
      return open_viewer(buf, pdf_of(buf))
    else
      return vim.notify("no pdf yet", vim.log.levels.WARN)
    end
  else
    return start_watch(buf)
  end
end
local function toggle_autosave()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].typst_mode then
    vim.b[buf]["typst_mode"] = nil
    release(buf)
  else
    vim.b[buf]["typst_mode"] = true
  end
  return set_status()
end
local function unload(buf)
  local s = states[buf]
  if (s and s.timer) then
    s.timer:stop()
    s.timer:close()
  else
  end
  stop(buf)
  states[buf] = nil
  return nil
end
local function quiet(f)
  local function _25_(args)
    f(args.buf)
    return nil
  end
  return _25_
end
local group = vim.api.nvim_create_augroup("typst_watch", {clear = false})
vim.api.nvim_clear_autocmds({group = group, buffer = 0})
vim.api.nvim_create_autocmd("BufUnload", {group = group, buffer = 0, callback = quiet(unload)})
vim.api.nvim_create_autocmd({"TextChanged", "InsertLeave"}, {group = group, buffer = 0, callback = quiet(autosave)})
local function _26_(args)
  if not vim.b[args.buf].typst_autosaving then
    release(args.buf)
  else
  end
  return nil
end
vim.api.nvim_create_autocmd("BufWritePost", {group = group, buffer = 0, callback = _26_})
vim.keymap.set("n", "<leader>mr", toggle, {buffer = 0, desc = "typst watch and zathura"})
return vim.keymap.set("n", "<leader>mt", toggle_autosave, {buffer = 0, desc = "typst autosave, holds errors while typing"})
