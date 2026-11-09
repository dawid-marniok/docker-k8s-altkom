# Dobra kolejność: najpierw zależności (zmieniają się rzadko), potem kod (zmienia się często).
FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
USER nobody
EXPOSE 5000
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]
