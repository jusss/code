from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/echo', methods=['POST'])
def echo():
    # Get the JSON data from the request
    data = request.get_json()
    
    # Return the same data as a JSON response
    return jsonify(data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port= 60080, debug=True)
