nix path-info -rS  github:pandecode/hermes  | sort -k2 -n | awk '{
  s=$2
  split($1, a, "-")
  name = substr($1, length(a[1]) + 2)
  if(s>=1073741824) printf "%.1fG\t%s\n", s/1073741824, name
  else if(s>=1048576) printf "%.1fM\t%s\n", s/1048576, name
  else if(s>=1024) printf "%.1fK\t%s\n", s/1024, name
  else printf "%dB\t%s\n", s, name
}'
