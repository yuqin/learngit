import pandas as pd
import numpy as np
import pickle
import random
import statsmodels.api as sm

from scipy.stats import pearsonr
#from minepy import MINE...

import xgboost as xgb
import sklearn
from sklearn.model_selection import KFold, train_test_split, GridSearchCV
from sklearn.metrics import confusion_matrix, mean_squared_error
from sklearn.datasets import load_iris, load_digits, load_boston
from sklearn.ensemble import RandomForestClassifier
from sklearn.ensemble import RandomForestRegressor
from sklearn import cross_validation
from sklearn.cross_validation import cross_val_score,ShuffleSplit
import pylab as pl
import matplotlib.pyplot as plt
#from loan-opr import xgboost

#/var/spool/mail/jiangyuqin 




from pyhive import hive 
conn=hive.Connection(host='10.0.16.22',username='jiangyuqin',password='1qaz@WSX',auth='LDAP')
cursor=conn.cursor()
cursor.execute("""
""")
X_df_1=pd.DataFrame(cursor.fetchall())
print(X_df_1)