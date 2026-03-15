(fn get_parent_dirs [_path]
  (var path _path)
  (local dirs [])
  (var prev nil)
  (while (and path (not= path prev))
    (table.insert dirs 1 path)
    (set prev path)
    (set path (vim.fn.fnamemodify path ":h")))
  dirs)

(fn load_file [path]
  (vim.notify (.. "Sourcing custom config from: " path) vim.log.levels.INFO)
  (let [(ok err) (pcall dofile path)]
    (when (not ok)
      (vim.notify (.. "Error sourcing custom config: " err)
                  vim.log.levels.ERROR))))

(fn load_fnl_file [path]
  (vim.notify (.. "Sourcing custom config from: " path) vim.log.levels.INFO)
  (if Fennel
      (let [(ok err) (pcall Fennel.dofile path)]
        (when (not ok)
          (vim.notify (.. "Error sourcing custom config: " err)
                      vim.log.levels.ERROR)))
      (vim.notify "no Fennel runtime available" vim.log.levels.ERROR)))

(local db-file (vim.fn.expand "~/.cache/nvim/db_nvimrc.json"))

(when (= (vim.fn.filereadable db-file) 0)
  (vim.fn.writefile [" {}"] db-file))

(fn get_hash [path]
  (let [handle (io.popen (string.format "sha256sum %q" path))]
    (when handle
      (let [out (handle:read :*l)]
        (handle:close)
        (when out
          (out:match "^(%w+)"))))))

(fn read-db []
  (vim.fn.json_decode (vim.fn.readfile db-file)))

(fn write-db [tbl]
  (vim.fn.writefile [(vim.fn.json_encode tbl)] db-file))

(fn remove_file_from_db [p]
  (let [tbl (read-db)]
    (tset tbl p nil)
    (write-db tbl)))

(fn value_database [p]
  (. (read-db) p))

(fn add_to_database [p allowed]
  (let [tbl (read-db)]
    (tset tbl p {: allowed :hash (if allowed (get_hash p) "")})
    (write-db tbl)))

(fn source-one [path loader]
  (let [db-val (value_database path)]
    (if (= db-val nil)
        (let [choice (vim.fn.confirm "Source this config file?" "&Yes\n&No")]
          (if (= choice 1)
              (do
                (add_to_database path true)
                (loader path))
              (do
                (vim.notify (.. "Denied: " path))
                (add_to_database path false))))
        (if db-val.allowed
            (if (= db-val.hash (get_hash path))
                (loader path)
                (do
                  (vim.print "File changed, need to re-auth")
                  (remove_file_from_db path)
                  (source-one path loader)))
            (vim.print (.. "Denied: " path))))))

(fn source_custom_config []
  (let [dirs (get_parent_dirs (vim.fn.getcwd))]
    (each [_ dir (ipairs dirs)]
      (let [lua-path (.. dir :/.nvimrc.lua)
            fnl-path (.. dir :/.nvimrc.fnl)]
        (when (= (vim.fn.filereadable lua-path) 1)
          (source-one lua-path load_file))
        (when (= (vim.fn.filereadable fnl-path) 1)
          (source-one fnl-path load_fnl_file))))))

(vim.api.nvim_create_autocmd :DirChanged
                             {:pattern "*"
                              :callback source_custom_config
                              :desc "Source custom .nvimrc.lua/.nvimrc.fnl from parent dirs up to cwd"})

(source_custom_config)
