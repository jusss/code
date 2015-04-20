/* gcc server-linux.c -lpthread -trigraphs */

#include <stdio.h>
#include <netinet/in.h>	/* for sockaddr_in */
#include <sys/types.h> /* for socket */
#include <stdlib.h>
#include <sys/socket.h> /* for socket */
#include <malloc.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <unistd.h>

/* if it needs more clients to connected, add this */
#define MAXCLIENT 12

int count=1; 
int sockfd[1000]={0};
int sockaddr_len=0;

struct sockaddr_in client_addr;	/* socket stuff */
struct sockaddr_in serv_addr;
pthread_mutex_t lock;

thread_run()
{
	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	while (1) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
main()
{
	pthread_t pids[MAXCLIENT];
	int i;

	sockaddr_len=sizeof(struct sockaddr);
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
	serv_addr.sin_port=htons(30802);
	sockfd[0]=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);


	bind(sockfd[0],(struct sockaddr*)&serv_addr,sockaddr_len);
	listen(sockfd[0],10);

	pthread_mutex_init(&lock,NULL);
loop:

	for (i = 0; i < MAXCLIENT; i++) {
		pthread_create(&pids[i], NULL, (void *)thread_run, NULL);
	}
	
	for (i = 0; i < MAXCLIENT; i++) {
		pthread_join(pids[i], NULL);
	}
	count=1;
	goto loop;
	return 0;
}
