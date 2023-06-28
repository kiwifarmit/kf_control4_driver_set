function RelayLoop(idRelay, Status)
    Dbg("Relay Loop Call for Relay: "..idRelay.." with Status: ".. Status)
    C4:SetTimer(1000, function(timer)
		  if Status == 0 then
			 PRX_CMD.OPEN(idRelay)
			 Status = 1
		  elseif Status == 1 then
			 PRX_CMD.CLOSE(idRelay)
			 Status = 2
		  elseif Status == 2 then
			 PRX_CMD.OPEN(idRelay)
			 Status = 3
		  end
		  if Status == 3 then
			 --PRX_CMD.OPEN(idRelay)
			 idRelay = idRelay + 1
			 Status = 0
		  end
		  if idRelay < 9 then
			 RelayLoop(idRelay, Status)
		  end
		  end)
    
end