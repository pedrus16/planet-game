function tostring(x)
  local s
  if type(x) == "table" then
    s = "{"
    local i, v = next(x)
    while i do
      s = s .. tostring(i) .. "=" .. tostring(v)
      i, v = next(x, i)
      if i then s = s .. "," end
    end
    return s .. "}"
  else return %tostring(x)
  end
end

-- Extend print to work better on tables
--   arg: objects to print
function print(...)
  for i = 1, getn(arg) do arg[i] = tostring(arg[i]) end
  call(%print, arg)
end
