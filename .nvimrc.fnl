(vim.api.nvim_create_autocmd :BufWritePost
                             {:pattern :*.fnl
                              :callback #(vim.fn.jobstart [:./compile.sh]
                                                          {:stdout_buffered true
                                                           :stderr_buffered true
                                                           :on_stderr (fn [_
                                                                           data]
                                                                        (if (and data
                                                                                 (not (= (. data
                                                                                            1)
                                                                                         "")))
                                                                            (vim.notify (table.concat data
                                                                                                      "\n")
                                                                                        vim.log.levels.ERROR)))
                                                           :on_exit (fn [_
                                                                         code]
                                                                      (if (= code
                                                                             0)
                                                                          (vim.notify "Fennel Compiled")))})})
