
#dependencias

sudo apt install openjdk-17-jdk -y

java -version
# Instalar Maven desde repositorios oficiales
sudo apt install maven -y

# Verificar instalación
mvn -version


mvn spring-boot:run

mvn clean

rm -rf target/*
