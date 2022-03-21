FROM gitpod/workspace-full

# Python 3.10.1
RUN pyenv update && pyenv install 3.10.1 && pyenv global 3.10.1

# Poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
ENV PATH "$HOME/.poetry/bin:$PATH"
