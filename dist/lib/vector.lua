vector = {}

function vector.length(x, y)
	return math.sqrt(math.pow(x, 2) + math.pow(y, 2))
end

function vector.normalize(x, y)
	local length = vector.length(x, y)
	if length > 0 then
		return x / length, y / length
	end
	return x, y
end

function vector.sub(x1, y1, x2, y2)
  return x1 - x2, y1 - y2
end

function vector.polar2cartesian(x, y)
	return math.sqrt(math.pow(x, 2) + math.pow(y, 2)), math.atan2(y, x)
end

function vector.cartesian2polar(length, direction)
	return length * math.cos(direction), length * math.sin(direction)
end

return vector
