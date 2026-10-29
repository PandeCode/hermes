;; vim.secure keeps the trust database: it asks before the first run and again
;; whenever the file changes. a file runs again once the cwd has left its
;; project and come back, a :cd inside the project does not run it twice
(var sourced {})

(fn parent_dirs [path]
  (local dirs [path])
  (each [dir (vim.fs.parents path)]
    (table.insert dirs 1 dir))
  dirs)

(fn run [path contents]
  (if (vim.endswith path :.fnl)
      (if Fennel
          (Fennel.eval contents {:filename path})
          (vim.notify "no Fennel runtime available" vim.log.levels.ERROR))
      ((assert (load contents (.. "@" path))))))

(fn source-one [path before]
  (when (= (vim.fn.filereadable path) 1)
    (tset sourced path true))
  (when (and (. sourced path) (not (. before path)))
    (let [contents (vim.secure.read path)]
      (when contents
        (vim.notify (.. "Sourcing custom config from: " path))
        (let [(ok err) (pcall run path contents)]
          (when (not ok)
            (vim.notify (.. "Error sourcing custom config: " err)
                        vim.log.levels.ERROR)))))))

(fn source_custom_config []
  (let [before sourced]
    (set sourced {})
    (each [_ dir (ipairs (parent_dirs (vim.fn.getcwd)))]
      (source-one (.. dir :/.nvimrc.lua) before)
      (source-one (.. dir :/.nvimrc.fnl) before))))

(vim.api.nvim_create_autocmd :DirChanged
                             {:pattern "*"
                              :callback source_custom_config
                              :desc "Source custom .nvimrc.lua/.nvimrc.fnl from parent dirs up to cwd"})

(source_custom_config)
