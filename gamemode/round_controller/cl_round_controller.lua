local round_status = 0

net.Receive("UpdateRoundStatus", function(len)
	round_status = net.ReadInt(4)
end)

function getRoundStatus()
	return round_status
end