#########################认识数据###############################

df.head()
#查看各字段名
df.info()
#设置id列为索引列
df=df.set_index('ID',drop=True)   
df.head()

#修改英文字段名为中文字段名
states={'SeriousDlqin2yrs':'好坏客户',
        'RevolvingUtilizationOfUnsecuredLines':'可用额度比值',
        'age':'年龄',
        'NumberOfTime30-59DaysPastDueNotWorse':'逾期30-59天笔数',
        'DebtRatio':'负债率',
        'MonthlyIncome':'月收入',
        'NumberOfOpenCreditLinesAndLoans':'信贷数量',
        'NumberOfTimes90DaysLate':'逾期90天笔数',
        'NumberRealEstateLoansOrLines':'固定资产贷款量',
        'NumberOfTime60-89DaysPastDueNotWorse':'逾期60-89天笔数',
        'NumberOfDependents':'家属数量'}
df.rename(columns=states,inplace=True)

#########################数据预处理################################
#########################缺失值处理###############################
print("月收入缺失比:{:.2%}".format(df['月收入'].isnull().sum()/df.shape[0]))
print("家属数量缺失比:{:.2%}".format(df['家属数量'].isnull().sum()/df.shape[0]))

#月收入缺失较大，使用平均值进行填充，家属数量缺失较少，将缺失的删掉，另外，如果字段缺失过大，将失去分析意义，可以将整个字段删
df=df.fillna({'月收入':df['月收入'].mean()})
df1=df.dropna()
df1.shape

#########################数据预处理################################
#########################异常值处理###############################
#通过箱线图观测异常值
import matplotlib.pyplot as plt
from pylab import mpl
mpl.rcParams['font.sans-serif'] = ['SimHei']
x1=df['可用额度比值']
x2=df['负债率']
x3=df1["年龄"]
x4=df1["逾期30-59天笔数"]
x5=df1["逾期60-89天笔数"]
x6=df1["逾期90天笔数"]
x7=df1["信贷数量"]
x8=df1["固定资产贷款量"]
fig=plt.figure(figsize=(20,15))
ax1=fig.add_subplot(221)
ax2=fig.add_subplot(222)
ax3=fig.add_subplot(223)
ax4=fig.add_subplot(224)
ax1.boxplot([x1,x2])
ax1.set_xticklabels(["可用额度比值","负债率"], fontsize=20)
ax2.boxplot(x3)
ax2.set_xticklabels("年龄", fontsize=20)
ax3.boxplot([x4,x5,x6])
ax3.set_xticklabels(["逾期30-59天笔数","逾期60-89天笔数","逾期90天笔数"], fontsize=20)
ax4.boxplot([x7,x8])
ax4.set_xticklabels(["信贷数量","固定资产贷款量"], fontsize=20)


#异常值处理消除不合逻辑的数据和超级离群的数据，可用额度比值应该小于1，年龄为0的是异常值，逾期天数笔数大于80的是超级离群数据，固定资产贷款量大于50的是超级离群数据，将这些离群值过滤掉，筛选出剩余部分数据
df1=df1[df1['可用额度比值']<1]
df1=df1[df1['年龄']>0]
df1=df1[df1['逾期30-59天笔数']<80]
df1=df1[df1['逾期60-89天笔数']<80]
df1=df1[df1['逾期90天笔数']<80]
df1=df1[df1['固定资产贷款量']<50]
df1.shape


####################探索分析#############################
###################单变量分析############################
#将年龄均分成5组，求出每组的总的用户数
age_cut=pd.cut(df1['年龄'],5)
age_cut_group=df1['好坏客户'].groupby(age_cut).count()
age_cut_group
#求各组的坏客户数
age_cut_grouped1=df1["好坏客户"].groupby(age_cut).sum()
age_cut_grouped1
#联结
df2=pd.merge(pd.DataFrame(age_cut_group),pd.DataFrame(age_cut_grouped1),left_index=True,right_index=True)
df2.rename(columns={'好坏客户_x':'总客户数','好坏客户_y':'坏客户数'},inplace=True)
df2
#加一列好客户数
df2.insert(2,"好客户数",df2["总客户数"]-df2["坏客户数"])
df2
#再加一列坏客户占比
df2.insert(2,"坏客户占比",df2["坏客户数"]/df2["总客户数"])
df2
ax1=df2[["好客户数","坏客户数"]].plot.bar(figsize=(10,5))
ax1.set_xticklabels(df2.index,rotation=15)
ax1.set_ylabel("客户数")
ax1.set_title("年龄与好坏客户数分布图")
#可以看出随着年龄的增长，坏客户率在降低，其中38~55之间变化幅度最大

####################探索分析#############################
###################多变量分析############################
import seaborn as sns
corr = df1.corr()#计算各变量的相关性系数
xticks = list(corr.index)#x轴标签
yticks = list(corr.index)#y轴标签
fig = plt.figure(figsize=(15,10))
ax1 = fig.add_subplot(1, 1, 1)
sns.heatmap(corr, annot=True, cmap="rainbow",ax=ax1,linewidths=.5, annot_kws={'size': 9, 'weight': 'bold', 'color': 'blue'})
ax1.set_xticklabels(xticks, rotation=35, fontsize=15)
ax1.set_yticklabels(yticks, rotation=0, fontsize=15)
plt.show()
#可以看到各变量之间的相关性比较小，所以不需要操作，一般相关系数大于0.6可以进行变量剔除


##########################特征选择##############################
