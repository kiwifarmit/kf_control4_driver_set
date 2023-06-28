import hug
import pickle

g_status = {
  "position" : 0,
  "target_position" : 0,
  "ramp_rate" : 25,
  "current_pos":0,
  "last_direction": "---",
  "state": "stop"
}
def read_status():
  global g_status
  try:
    with open("g_status.bin",'rb') as pfile:
      g_status=pickle.load(pfile)
  except FileNotFoundError:
    save_status()

def save_status():
  global g_status
  with open("g_status.bin",'wb') as pfile:
    pickle.dump(g_status,pfile)

@hug.get('/roller/{id}')
def roller(id, go=None, roller_pos=None):
    global g_status
    read_status()
    
    if (g_status["state"]=="open"):
      g_status["last_direction"] = "close"
    elif (g_status["state"]=="close"):
      g_status["last_direction"] = "open"

    if (go == "open"):
      g_status["target_position"] = 100
      g_status["state"] = "open"
    elif (go == "close"):
      g_status["target_position"] = 0
      g_status["state"] = "close"
    elif (go == "to_pos"):
      g_status["target_position"] = int(roller_pos)
      g_status["state"] = "to_pos"
    elif (go == "stop"):
      g_status["target_position"] = g_status["current_pos"]


      
    
    if (g_status["target_position"] > g_status["current_pos"]):
      
      if (g_status["current_pos"]+g_status["ramp_rate"] <= g_status["target_position"]):
        g_status["current_pos"] = g_status["current_pos"]+g_status["ramp_rate"]
        
      else:
        g_status["current_pos"] = g_status["target_position"]
        g_status["state"] = "stop"

    if (g_status["target_position"] <= g_status["current_pos"]):
      if (g_status["current_pos"]-g_status["ramp_rate"] > g_status["target_position"]):
        g_status["current_pos"] = g_status["current_pos"]-g_status["ramp_rate"]
        
      else:
        g_status["current_pos"] = g_status["target_position"]
        g_status["state"] = "stop"
    

    save_status()
    return {
    "state": g_status["state"],
    "power": 100 ,
    "is_valid": False,
    "safety_switch": False,
    "overtemperature": False,
    "stop_reason": "normal",
    "last_direction": g_status["last_direction"],
    "current_pos": g_status["current_pos"],
    "calibrating": False,
    "positioning": True
}

