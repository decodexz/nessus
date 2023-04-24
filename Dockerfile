FROM ubuntu
ADD Nessus_10.5.1_Ubuntu.sh /home/
WORKDIR /home
RUN bash Nessus_10.5.1_Ubuntu.sh 
EXPOSE 11127