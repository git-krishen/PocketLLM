# PocketLLM
This is a Flutter app which allows you to download and chat with a local ai model! With a minimalist, easy-to-understand interface, it allows you to seamlessly utilize the power of the latest and most advanced LLMs without any of it leaving the palm of your hand. Whether you're looking for offline access to an internet's worth of information, the complete privacy of an llm conversation that never has to (and never does) leave your phone, or anything else, there's something for anyone in having an on-device, offline assistant to answer the questions you need answered.
## Backstory
This project was inspired by an interesting paper I read on the capabilities of local llms to encapsulate incredible amounts of information relative to their size. The premise was that LLMs can be thought of as hyper efficient compression algorithms, which encode information in an extremely dense (highly entropic) fashion. This made me think about times where I wanted to look up something, but didn't have any internet, such as exploring remote national parks like Big Bend or Wrangell St. Elias. If I was in a pickle, I would've had to figure out everything myself! But, with a tool like this, you could essentially have an internet's worth of information at your fingertips without ever needing even a single bar of connection, as long as you already have a model downloaded. Already being into the local llm scene, I knew I had to make it happen. After a lot of work, from teaching myself Flutter to creating a RESTful backend with Python Flask to learning how to work directly with llama.cpp's low level functions, this was the result! It's still got plenty of work to be done, but I'm proud of what I've achieved.
## Tips
  - Models between 3b and 8b parameters generally work best, depending on what device you have/how powerful it is.
  - Choosing quantized models can give you a huge performance boost, but will decrease accuracy, with lower quantizations yielding a worse performance penalty.
  - If you're running into performance issues, choose a smaller or more aggresively quantized model.
  - Generally, as long as the quantization is q3 or above, a larger model quantized is better than an equal performance smaller model with less quantization. This isn't a hard and fast rule though, so feel free to experiment.
  - If you're having trouble compiling the project, make sure you initialize the git submodules for flutter_local_llm.
## Compatibility
This is theoretically compatible with
  - macOS (ARM64, x86_64)
  - Windows (x86_64)
  - Linux (x86_64)
  - Android (ARM64, x86_64)
  - iOS (ARM64)
  - iPadOS (ARM64)

However, this has only been tested on Android x86_64 so beware! I will update this once I test on more platforms, but being a high schooler I don't exactly have access to a ton of development devices.
## Source Code
The source code for this is hosted on my [github](https://github.com/git-krishen/PocketLLM).
## License
This is licensed under the AGPL v3 License. If you want to know more, see the [LICENSE](LICENSE) file.