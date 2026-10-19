vim.bo.errorformat = table.concat({"%f:%l:%c: %trror: %m", "%f:%l:%c: %tarning: %m", "%-G%.%#"}, ",")
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
local function open_viewer(buf, pdf)
  local function _2_()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf]["typst_viewer"] = nil
      return vim.cmd.redrawstatus({bang = true})
    else
      return nil
    end
  end
  vim.b[buf]["typst_viewer"] = spawn({"zathura", pdf}, {on_exit = _2_})
  return vim.cmd.redrawstatus({bang = true})
end
local function absolute(line, cwd)
  local function _4_(path, rest)
    return (cwd .. "/" .. path .. rest)
  end
  return (line:gsub("^([^/][^:]*)(:%d+:%d+: )", _4_))
end
local function start_watch(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  local pdf = (vim.fn.fnamemodify(file, ":r") .. ".pdf")
  local cwd = vim.fn.getcwd()
  local title = ("typst watch " .. vim.fn.fnamemodify(file, ":~:."))
  local efm = vim.bo[buf].errorformat
  local pending = ""
  local lines = {}
  local compiled = false
  local opened = false
  local viewed = alive_3f(vim.b[buf].typst_viewer)
  local function publish()
    do
      local items = vim.fn.getqflist({lines = lines, efm = efm}).items
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
        Utils.set_qf(title, lines, efm)
      else
      end
      if (errors > 0) then
        if not opened then
          opened = true
          vim.cmd("botright copen")
          vim.cmd("wincmd p")
        else
        end
      elseif (mine and (0 == #items)) then
        vim.cmd.cclose()
      else
      end
    end
    if (not viewed and (0 == vim.b[buf].typst_errors) and (1 == vim.fn.filereadable(pdf))) then
      viewed = true
      open_viewer(buf, pdf)
    else
    end
    return vim.cmd.redrawstatus({bang = true})
  end
  local function on_output(_, data)
    data[1] = (pending .. data[1])
    pending = table.remove(data)
    for _0, line in ipairs(data) do
      if line:find("^%[[%d:]+%] compiling") then
        lines = {}
        compiled = false
        opened = false
      elseif line:find("^%[[%d:]+%] compiled") then
        compiled = true
      elseif compiled then
        table.insert(lines, absolute(line, cwd))
      else
      end
    end
    if (compiled and vim.api.nvim_buf_is_valid(buf)) then
      return publish()
    else
      return nil
    end
  end
  vim.cmd("silent! wall")
  vim.b[buf]["typst_errors"] = 0
  local function _12_()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf]["typst_watch"] = nil
      return vim.cmd.redrawstatus({bang = true})
    else
      return nil
    end
  end
  vim.b[buf]["typst_watch"] = spawn({"typst", "watch", "--diagnostic-format", "short", file}, {on_stderr = on_output, on_exit = _12_})
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
  local pdf = (vim.fn.expand("%:p:r") .. ".pdf")
  if (watch and viewer) then
    return stop(buf)
  elseif watch then
    if (1 == vim.fn.filereadable(pdf)) then
      return open_viewer(buf, pdf)
    else
      return vim.notify("no pdf yet", vim.log.levels.WARN)
    end
  else
    return start_watch(buf)
  end
end
local group = vim.api.nvim_create_augroup("typst_watch", {clear = false})
vim.api.nvim_clear_autocmds({group = group, buffer = 0})
local function _17_(_241)
  return stop(_241.buf)
end
vim.api.nvim_create_autocmd("BufUnload", {group = group, buffer = 0, callback = _17_})
return vim.keymap.set("n", "<leader>mr", toggle, {buffer = 0, desc = "typst watch and zathura"})
