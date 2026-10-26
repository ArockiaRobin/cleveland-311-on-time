"""
Cleveland 311 on-time dashboard
--------------------------------
Draws a one-page dashboard image (images/dashboard.png) from the results
of sql/03_analysis.sql. Numbers are copied from the SQL output so the
image always matches the documented queries.

Run from the repository root:
    pip install matplotlib
    python python/dashboard.py
"""
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10})
navy='#1f3a68'; grey='#9aa5b4'; bg='#f4f6fa'; red='#c0392b'
# Monthly on-time % by month requested (03_analysis.sql, monthly version).
# Feb 2024 and Oct 2026 are left out because they are partial months.
m=[('2024-03',43.8),('2024-04',43.5),('2024-05',45.1),('2024-06',63.4),('2024-07',54.5),('2024-08',53.9),('2024-09',65.1),('2024-10',68.2),('2024-11',65.0),('2024-12',50.2),('2025-01',51.5),('2025-02',76.9),('2025-03',73.8),('2025-04',71.4),('2025-05',59.1),('2025-06',57.9),('2025-07',56.9),('2025-08',61.7),('2025-09',84.5),('2025-10',86.3),('2025-11',84.7),('2025-12',84.0),('2026-01',71.9),('2026-02',61.9),('2026-03',64.9),('2026-04',73.1),('2026-05',64.9),('2026-06',64.5),('2026-07',82.4),('2026-08',83.5),('2026-09',90.3)]
# ---- Page setup and title ----
fig=plt.figure(figsize=(16,9),dpi=120,facecolor=bg)
fig.text(0.03,0.945,'Cleveland 311: Are Requests Closed On Time?',fontsize=22,fontweight='bold',color=navy)
fig.text(0.03,0.91,'Closed requests with a target date and valid timestamps · Feb 28, 2024 – Oct 23, 2026 · Source: City of Cleveland Open Data Portal',fontsize=11,color='#555')
# ---- KPI cards: (title, value, note) from A1, A7 and the days-to-close query ----
cards=[('On-time rate','68.1%','closed on or before target date'),('Requests analyzed','179,842','of 188,406 total'),('Avg days to close','16.6','days, same requests'),('Open past target','2,689','not in on-time rate')]
for i,(t,v,s) in enumerate(cards):
    x=0.03+i*0.2375
    ax=fig.add_axes([x,0.74,0.22,0.14]); ax.axis('off')
    ax.add_patch(FancyBboxPatch((0,0),1,1,boxstyle='round,pad=0,rounding_size=0.06',fc='white',ec='#d5dbe5',transform=ax.transAxes))
    ax.text(0.06,0.74,t,fontsize=12,color='#555',transform=ax.transAxes)
    ax.text(0.06,0.33,v,fontsize=30,fontweight='bold',color=red if i==3 else navy,transform=ax.transAxes)
    ax.text(0.06,0.1,s,fontsize=10,color='#777',transform=ax.transAxes)
# Helper: a white chart panel with a left-aligned title
def panel(rect,title):
    ax=fig.add_axes(rect); ax.set_facecolor('white')
    for s in ['top','right']: ax.spines[s].set_visible(False)
    ax.set_title(title,loc='left',fontsize=13,fontweight='bold',color=navy,pad=8); return ax
# ---- On-time % by agency (A2) ----
ax=panel([0.13,0.40,0.24,0.27],'On-time % by agency')
ag=[('Building & Housing',57.7),('Public Works',69.5),('Parks & Recreation',73.6)]
b=ax.barh([a for a,_ in ag],[v for _,v in ag],color=navy,height=0.55)
for r,(_,v) in zip(b,ag): ax.text(v+1,r.get_y()+r.get_height()/2,f'{v}%',va='center',fontsize=10)
ax.set_xlim(0,100); ax.set_xticks([]); ax.spines['bottom'].set_visible(False); ax.tick_params(axis='y',length=0)
# ---- Monthly trend line (A6 monthly) ----
ax=panel([0.44,0.40,0.53,0.27],'Monthly on-time % (by month requested)')
xs=range(len(m)); ax.plot(xs,[v for _,v in m],color=navy,lw=2,marker='o',ms=3)
ax.set_ylim(30,100); ax.set_yticks([40,60,80,100]); ax.set_yticklabels(['40%','60%','80%','100%'])
ticks=[i for i,(k,_) in enumerate(m) if k[5:] in ('03','09')]
ax.set_xticks(ticks); ax.set_xticklabels([m[i][0] for i in ticks],fontsize=9); ax.grid(axis='y',color='#e5e8ee')
ax.text(len(m)-1,93,'90.3%',ha='right',fontsize=9,color=navy)
# ---- Lowest on-time request types with 100+ requests (A4) ----
ax=panel([0.20,0.05,0.30,0.27],'Lowest on-time request types (100+ requests)')
rt=[('Electrical Issue',9.5),('No Water/No Hot Water',14.6),('Graffiti Removal',21.6),('Pothole Repair',25.9),('Illegal Use of Property',33.8),('Vacant Property',34.3)]
b=ax.barh([a for a,_ in rt],[v for _,v in rt],color=red,height=0.55); ax.invert_yaxis()
for r,(_,v) in zip(b,rt): ax.text(v+1,r.get_y()+r.get_height()/2,f'{v}%',va='center',fontsize=10)
ax.set_xlim(0,60); ax.set_xticks([]); ax.spines['bottom'].set_visible(False); ax.tick_params(axis='y',length=0)
# ---- Data quality panel (02_data_checks.sql) ----
ax=fig.add_axes([0.57,0.05,0.40,0.27]); ax.axis('off')
ax.add_patch(FancyBboxPatch((0,0),1,1,boxstyle='round,pad=0,rounding_size=0.03',fc='white',ec='#d5dbe5',transform=ax.transAxes))
ax.text(0.04,0.86,'Data quality checks',fontsize=13,fontweight='bold',color=navy,transform=ax.transAxes)
rows=[('0','duplicate reference numbers'),('915','closed before requested (excluded)'),('3,660','no target date (excluded)'),('429','no ward (excluded from ward view)'),('100%','status matches closed date')]
for i,(v,t) in enumerate(rows):
    y=0.68-i*0.145
    ax.text(0.04,y,v,fontsize=14,fontweight='bold',color=red if v in('915','3,660') else navy,transform=ax.transAxes)
    ax.text(0.22,y,t,fontsize=11,color='#333',transform=ax.transAxes)
fig.text(0.97,0.012,'Built with SQL (SQLite) and Python · github.com/ArockiaRobin/cleveland-311-on-time',ha='right',fontsize=9,color='#777')
# ---- Footer and save ----
fig.savefig('images/dashboard.png',facecolor=bg)
