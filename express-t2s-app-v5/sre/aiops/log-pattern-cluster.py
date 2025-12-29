from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans

logs = open("logs.txt").read().split("\n")
vectorizer = TfidfVectorizer()
X = vectorizer.fit_transform(logs)

kmeans = KMeans(n_clusters=5)
kmeans.fit(X)

print("Cluster centers:")
print(kmeans.cluster_centers_)