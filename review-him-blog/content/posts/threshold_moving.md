---
title: "Threshold moving"
date: 2024-02-13T14:56:14+07:00
---

# Зачем?
Когда у нас примерно одинаковое количество примеров для разных классов, не возникает такой проблемы, как выбор трэшхолда, поскольку тут интуитивно понятно, что значение вероятности больше 0.5 означает позитивное предсказание, а меньше означает негативное.

Но что делать, когда у нас есть перевес в данных в какую-либо сторону? Или цена ошибки в каком либо классе больше, чем в другом?
Тогда и нужно решать задачу подбора трэшхолда.
Для решения этой задачи существует не один подход, а в этой статье я рассмотрю лишь часть из них.

# Построение ROC кривой
Для построения этой кривой нужно взять массив трэшхолдов, по ним посчитать предсказания. Для каждого трэшхолда подсчитать false-positive rate (FPR) и true-positive rate (TPR) и расположить эти точки на графике, где вдоль оси x идут значения FPR, а вдоль оси y значения TPR. Также необходимо построить диагональ из точки $[0,1]$ в точку $[1,0]$, которая будет обозначать предсказания одного самого распространенного класса.

Как из этой кривой подобрать самый подходящий трэшхолд? Визуально это трэшхолд самой верхней левой точки на графике. Но как найти эту точку точно?
Для этого понадобится получить значения TPR и FPR для каждого трэшхолда и посчитать геометрическое среднее между TPR и (1-FPR). Трэшхолд наибольшего среднего  значения и будет являться оптимальным.

Есть еще один вариант, как можно найти оптимальный трэшхолд. Для этого нужно воспользоваться Youden's J statistic, методом, который напрямую создан для подбора оптимального трэшхолда. Его суть заключается в том, что необходимо из TPR вычесть FPR для каждого трэшхолда. В таком случае получится, что значение для наибольшего трэшхолда снова будет оптимальным.
## Как это выглядит в коде?

Предположим у нас есть X, y.
Находим предсказания, считаем tpr и fpr из библиотеки sklearn:
```python
from sklearn.metrics import roc_curve
fpr, tpr, thresholds = roc_curve(y, yhat)
```

Затем считаем геометрическое среднее, как говорилось раньше между tpr и (1-fpr):
```python
gmeans = np.sqrt(tpr * (1-fpr))
```

Ищем наибольшее значение среднего и получаем оптимальный трэшхолд:
```python
opt_threshold = thresholds[np.argmax(gmeans)]
```

Для подсчета статистики Юдена, все еще проще:
```python
opt_threshold = thresholds[np.argmax(tpr - fpr)]
```

Вот и все.

Визуально это выглядит так:
![График ROC кривой](/images/threshold_01.png)

Еще с помощью этой кривой можно описать качество предсказаний модели с помощью единственного числа - AUC. Сравнивая значения этого показателя для разных моделей, можно выбрать модель с наилучшим результатом.

# Precision-Recall Curve
В отличие от ROC кривой, которая показывает компромисс между TPR и FPR для разных трэшхолдов, precision-recall кривая сфокусирована на точности модели в предсказании только положительного класса (меньшего).

*Precision* - это отношение числа TP к сумме всех TP + FP. Это значение показывает, как хорошо модель предсказывает положительный класс.
*Recall* - это отношение числа TP к сумме TP + FN. Показывает вероятность классификатора предсказать правильное положительное значение.

Для того, чтобы построить кривую precision-recall на определенном сэте трэшхолдов, необходимо также предсказать вероятности для каждого трэшхолда, посчитать значения precision и recall и отобразить эти значения для каждого трэшхолда на оси координат, где по оси x располагаются значения recall, а по оси y - значения precision.

Также на этом графике принято отображать горизонтальную линию, означающую отношение положительных примеров ко всем в датасете, или используют какое-то маленькое фиксированное число.

Наилучшие значения модели получаются при выборе трэшхолда в максимально правой верхней точке, когда precision и recall максимальны.

# Как использовать в коде?
```python
from sklearn.metrics import precision_recall_curve
precision, recall, thresholds = precision_recall_curve(y, yhat)
```

Теперь нужно определить оптимальный трэшхолд.
Сделать это можно с помощью оптимизации F1-score функции, которая означает ни что иное, как гармоническое среднее между precision и recall. Считаем F1 для каждого трэшхолда и находим оптимальное значение трэшхолда там, где F1 достигает максимального значения.

```python
F = (2 * precision * recall) / (precision + recall)

optim_threshold = thresholds[np.argmax(F)]
```

Можно построить график того, как это выглядит:
```python
fscore = (2 * precision * recall) / (precision + recall)
ix = argmax(fscore)
print('Best Threshold=%f, F score=%.3f' % (thresholds[ix], fscore[ix]))

pyplot.plot([0,1], [0.01, 0.01], linestyle='--', label='No Skill')
pyplot.plot(precision, recall, marker='.', label='Logistic')
pyplot.scatter(precision[ix], recall[ix], marker='o', color='black', label='Best')

pyplot.xlabel('Precision')
pyplot.ylabel('Recall')
pyplot.legend()

pyplot.show()
```
![График Precision-Recall кривой](/images/threshold_02.png)

# Источники:
>https://machinelearningmastery.com/threshold-moving-for-imbalanced-classification/