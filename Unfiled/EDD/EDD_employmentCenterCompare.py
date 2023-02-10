import pandas as pd
import numpy as np
import os
import seaborn as sns
import matplotlib.pyplot as plt

pd.set_option('display.max_columns', None)
pat = r'C:\Users\skl\PycharmProjects\QA\EDD\EmploymentCenters'
fil1 = 'employmentCenters.csv'
fil2 = 'mergeWithEmploymentCenter.csv'


df1 = pd.read_csv(os.path.join(pat, fil1), encoding = 'latin-1')
df2 = pd.read_csv(os.path.join(pat, fil2), encoding = 'latin-1')
df2 = df2.dropna()
df2 = df2[~df2['employment_center_name'].str.contains('City')]
df2 = df2[~df2['employment_center_name'].str.contains('Unincorporated')]


df1['source'] = 'Employment Center'
df2['source'] = 'EDD'


df = pd.concat([df1,df2[['employment_center_name', 'jobs', 'source']]])
df3 = df1.merge(df2,how='right', left_on='employment_center_name', right_on='employment_center_name')
df3['jobsDiff'] = df3['jobs_y'] - df3['jobs_x']


sns.set(font_scale = 1.2)
ax = sns.barplot(x = 'employment_center_name', y = 'jobs', hue = 'source', data = df)
ax.set_xticklabels(ax.get_xticklabels(),rotation=45, ha = 'right')
plt.show()

ax = sns.barplot(x = 'employment_center_name', y = 'jobsDiff', hue = 'tier', dodge = False, data = df3[abs(df3['jobsDiff'])>1000])
ax.set_xticklabels(ax.get_xticklabels(),rotation=45, ha = 'right')
sns.set(font_scale = 1.4)
ax.set_ylabel('Differences in Jobs > 1000')
ax.set_title('Major Differences between EDD and Employment Center Data')



print('tt')