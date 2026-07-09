def pathstr:
  map(
    if type == "number" then "[]"
    else tostring
    end
  )
  | join(".");

paths
| pathstr
| select(length > 0)
