;; code actions for nix files, <leader>ca lists them next to statix's:
;; Make_Flake on a file with a mkShell and no flake.nix next to it,
;; Add_Default_Package on a flake with no packages output

(fn field [node name]
  (. (node:field name) 1))

(fn text_of [buf node]
  (vim.treesitter.get_node_text node buf))

(fn root_of [buf]
  (let [parser (vim.treesitter.get_parser buf :nix {:error false})]
    (when parser
      (: (. (parser:parse) 1) :root))))

;; the first node from node down, itself included, that pred? takes
(fn find [node pred?]
  (if (pred? node) node (accumulate [found nil child (node:iter_children)
                                     &until found]
                          (find child pred?))))

;; the binding named name in an attrset or let
(fn binding [buf node name]
  (find node #(and (= ($:type) :binding) (= (: ($:parent) :parent) node)
                   (= (text_of buf (field $ :attrpath)) name))))

(fn slice [buf sr sc er ec]
  (table.concat (vim.api.nvim_buf_get_text buf sr sc er ec {}) "\n"))

(fn sibling [buf name]
  (.. (vim.fs.dirname (vim.api.nvim_buf_get_name buf)) "/" name))

(fn exists? [path]
  (= 1 (vim.fn.filereadable path)))

;; a new file in this window or a split, without the template newfile.lua
;; would put in
(fn open_new [path snippet split?]
  (let [ei vim.o.eventignore]
    (set vim.o.eventignore :BufNewFile)
    (vim.cmd (.. (if split? :split :edit) " " (vim.fn.fnameescape path)))
    (set vim.o.eventignore ei)
    (vim.snippet.expand snippet)))

(fn mkshell? [buf node]
  (and (= (node:type) :apply_expression)
       (not= nil (: (text_of buf (field node :function)) :match "mkShell%w*$"))))

;; (treefmt pkgs) goes on the end of the shell's packages, on its own line
;; when ] is
(fn treefmt_at [buf shell]
  (let [args (field shell :argument)
        packages (binding buf args :packages)
        list (and packages
                  (find (field packages :expression)
                        #(= ($:type) :list_expression)))]
    (if list
        (let [(er ec) (list:end_)
              before (slice buf er 0 er (- ec 1))]
          (if (before:match "^%s*$")
              [er (- ec 1) (.. "  (treefmt pkgs)\n" before)]
              [er (- ec 1) "(treefmt pkgs) "]))
        (= (args:type) :attrset_expression)
        (let [(sr sc) (args:start)]
          [sr (+ sc 1) "\n  packages = [ (treefmt pkgs) ];"])
        (let [(sr sc) (args:start)]
          (vim.notify "mkShell takes no attrset here, add (treefmt pkgs) to it"
                      vim.log.levels.WARN)
          [sr sc ""]))))

;; lib ? pkgs.lib comes over as inherit (pkgs) lib, statix's way of
;; writing lib = pkgs.lib
(fn let_binding [name default]
  (let [from (default:match (.. "^([%w_.]+)%." (vim.pesc name) "$"))]
    (if from
        (.. "  inherit (" from ") " name ";")
        (.. "  " name " = " default ";"))))

;; { pkgs ? ..., lib ? pkgs.lib }: lib comes over as a let, pkgs is the
;; flake's. a formal with no default has nothing to come over as
(fn formal_lets [buf expr]
  (let [lets []
        formals (field expr :formals)]
    ;; pkgs: pkgs.mkShell has no formals, pkgs is the flake's
    (each [formal (if formals (formals:iter_children) #nil)]
      (let [name (and (= (formal:type) :formal)
                      (text_of buf (field formal :name)))
            default (and name (field formal :default))]
        (if default
            (when (not= name :pkgs)
              (table.insert lets (let_binding name (text_of buf default))))
            (and name (not= name :pkgs))
            (vim.notify (.. name " has no default, the flake has no " name
                            " to give it")
                        vim.log.levels.WARN))))
    (if (< 0 (length lets))
        (.. "let\n" (table.concat lets "\n") "\nin\n")
        "")))

;; the shell is the body of the function shell.nix is, or just the mkShell
;; call when it is not a function
(fn shell_text [buf]
  (let [expr (field (root_of buf) :expression)
        fn? (= (expr:type) :function_expression)
        body (if fn? (field expr :body) expr)
        shell (find body #(mkshell? buf $))]
    (when shell
      (let [from (if fn? body shell)
            (sr sc er ec) (from:range)
            [r c text] (treefmt_at buf shell)]
        (when (and (not fn?) (not= shell expr))
          (vim.notify "only the mkShell call came over" vim.log.levels.WARN))
        (.. (if fn? (formal_lets buf expr) "") (slice buf sr sc r c) text
            (slice buf r c er ec))))))

;; flake.nix from the flake template with the shell as its devShell, plus the
;; files a flake comes with. the shell file stays
(fn make_flake [buf]
  (let [shell (shell_text buf)]
    (if (not shell)
        (vim.notify "no mkShell here" vim.log.levels.WARN)
        (let [path (sibling buf :flake.nix)
              ;; the devShell sits 8 deep in the template
              devshell (shell:gsub "\n([^\n])" "\n        %1")
              flake (: (Utils.snippet :nix :flake) :gsub
                       "default = pkgs%.mkShell %b{};"
                       #(.. "default = " (Utils.snippet_escape devshell) ";") 1)]
          (Utils.flake_files (vim.fs.dirname path))
          (open_new path flake)))))

;; the attrset that outputs = { self, ... }: gives, under a let or not
(fn outputs_of [buf root]
  (let [top (field root :expression)
        outputs (and (= (top:type) :attrset_expression)
                     (binding buf top :outputs))
        f (and outputs (field outputs :expression))
        body (and f (= (f:type) :function_expression) (field f :body))]
    (if (and body (= (body:type) :let_expression)) (field body :body)
        (and body (= (body:type) :attrset_expression)) body)))

;; the last binding in outputs, packages goes after it when there is no devShells
(fn last_output [outputs]
  (find outputs #(and (= ($:type) :binding) (= (: ($:parent) :parent) outputs)
                      (= nil ($:next_named_sibling)))))

(local package_kinds [[:pkg :stdenv]
                      [:pkgrust :rust]
                      [:pkggo :go]
                      [:pkgzig :zig]])

;; a package snippet for the project itself: src is the flake's folder
(fn local_package [kind dir]
  (let [text (: (Utils.snippet :nix kind {1 (vim.fs.basename dir)}) :gsub
                "src = fetchFromGitHub %b{};" "src = ./.;")
        keep #(not (or (= $ "  fetchFromGitHub,") ($:match "^%s*homepage = ")))]
    (table.concat (vim.tbl_filter keep (vim.split text "\n")) "\n")))

;; packages.default from ./package.nix with the template's forAll, in front
;; of devShells or after the last output. with no package.nix yet, one is
;; made from the package snippet picked
(fn add_default_package [buf]
  (let [outputs (outputs_of buf (root_of buf))
        devshells (binding buf outputs :devShells)
        last (last_output outputs)
        (_ c) (: (or devshells last) :start)
        ind (string.rep " " c)
        packages ["packages = forAll (pkgs: {"
                  (.. ind "  default = pkgs.callPackage ./package.nix { };")
                  (.. ind "});")]]
    (if devshells
        (let [(r c) (devshells:start)]
          (vim.api.nvim_buf_set_text buf r c r c
                                     (doto packages
                                       (table.insert "")
                                       (table.insert ind))))
        (let [(r c) (last:end_)]
          (tset packages 1 (.. ind (. packages 1)))
          (vim.api.nvim_buf_set_text buf r c r c
                                     (doto packages
                                       (table.insert 1 "")
                                       (table.insert 1 "")))))
    (let [path (sibling buf :package.nix)]
      (when (not (exists? path))
        (vim.ui.select package_kinds
                       {:prompt "package.nix for" :format_item #(. $ 2)}
                       (fn [kind]
                         (when kind
                           (open_new path
                                     (local_package (. kind 1)
                                                    (vim.fs.dirname path))
                                     true))))))))

(fn actions [params]
  (let [buf params.bufnr
        root (root_of buf)
        found []]
    (when root
      (when (and (not (exists? (sibling buf :flake.nix)))
                 (find root #(mkshell? buf $)))
        (table.insert found {:title :Make_Flake :action #(make_flake buf)}))
      (let [outputs (outputs_of buf root)]
        (when (and outputs (last_output outputs)
                   (not (binding buf outputs :packages)))
          (table.insert found
                        {:title :Add_Default_Package
                         :action #(add_default_package buf)}))))
    found))

(local null_ls (require :null-ls))

;; this file runs for every nix buffer, the source is global
(when (not (null_ls.is_registered :nix-actions_no_show))
  (null_ls.register {:name :nix-actions_no_show
                     :method [null_ls.methods.CODE_ACTION]
                     :filetypes [:nix]
                     :generator {:fn actions}}))
