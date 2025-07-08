import re
from flask import Flask, request, jsonify
from huggingface_hub import hf_hub_url, list_repo_files

app = Flask(__name__)

def get_model_id(url):
  if "huggingface.co/" not in url:
    return None
  parts = url.strip("/").split("/")[-2::]
  return f"{parts[0]}/{parts[1]}" if len(parts)>=2 else None

def list_quantizations(model_id):
  files = list_repo_files(model_id)
  gguf_files = list(filter(lambda file: file.lower().endswith('.gguf') and find_quantization(file) is not None, files))
  if not gguf_files:
    return None
  # I LOVE LIST COMPREHENSIONS!!! RAAAAH!!!
  quantizations = [find_quantization(file) for file in gguf_files]
  download_links = [hf_hub_url(model_id,filename) for filename in gguf_files]
  # Combining both lists into a dictionary
  pairs = dict(zip(quantizations, download_links))
  # Making sure there's no null key
  pairs = {key: value for key, value in pairs.items() if key is not None}
  if not pairs:
    return None
  return pairs

 
def find_quantization(filename):
  match = re.search(r"(?:[.-])((?:UD-)?(?:f[p]?16|BF16|I?Q[A-Z0-9_]+))(?=(-\d+-of-\d+)??\.gguf)", filename)
  # The "not match.group(2)" filters out sharded files...because surprisingly I actually do have a limit to how much I like to make myself suffer
  if match and not match.group(2):
    return match.group(1)
  return None
    

@app.route("/get-compatible-models", methods=["GET"])
def get_compatible_models():
  model_url = request.args.get("model_url")

  if not model_url:
    return jsonify({
      "error": "Request is missing model url"
    }), 400
  
  model_id = get_model_id(model_url)
  if not model_id:
    return jsonify({
      "error": "URL does not contain a model"
    }), 400
  
  options = list_quantizations(model_id)

  # Maybe I'll get it to work with sharded downloads later idk
  if not options:
    return jsonify({
      "error": "No gguf files available or file is split into pieces (not supported)"
    }), 501
  
  # Handles any potential error message slipping through
  if isinstance(options, tuple) and len(options)==2:
    return jsonify(options[0]), options[1]

  # Sorts output for consistency
  options = dict(sorted(options.items()))
  
  # Converts dictionary into array of tuples to comply with standard JSON formatting
  converted = [{"quantization": q, "download_link": l} for q, l in options.items()]
  return jsonify(
    converted
  ), 200
