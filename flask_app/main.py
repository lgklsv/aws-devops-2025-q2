from flask import Flask, Response
from prometheus_client import generate_latest, Counter, Histogram
from werkzeug.middleware.dispatcher import DispatcherMiddleware
import time

app = Flask(__name__)

REQUESTS_TOTAL = Counter(
    'flask_http_requests_total',
    'Total HTTP requests to the Flask application.',
    ['method', 'endpoint']
)

REQUEST_LATENCY_SECONDS = Histogram(
    'flask_http_request_latency_seconds',
    'HTTP request latency in seconds.',
    ['method', 'endpoint']
)

@app.route('/')
def hello():
    method = 'GET' 
    endpoint = '/' 

    start_time = time.time()

    REQUESTS_TOTAL.labels(method=method, endpoint=endpoint).inc()

    response = 'Hello, World!'

    latency = time.time() - start_time
    REQUEST_LATENCY_SECONDS.labels(method=method, endpoint=endpoint).observe(latency)

    return response


@app.route('/metrics') 
def metrics():
    return Response(generate_latest(), mimetype='text/plain; version=0.0.4; charset=utf-8')
