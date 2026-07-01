#!/bin/bash
# ~/.config/i3/ws-prev.sh  
current=$(i3-msg -t get_workspaces | python3 -c "
import sys,json
ws=json.load(sys.stdin)
nums=sorted(w['num'] for w in ws)
focused=next(w['num'] for w in ws if w['focused'])
idx=nums.index(focused)
print(nums[(idx-1) % len(nums)])
")
i3-msg workspace $current
