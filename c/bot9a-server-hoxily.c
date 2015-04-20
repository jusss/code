#include <stdio.h>
#include <stdlib.h>
#include <winsock.h>
#include <malloc.h>
#include <windows.h>
#include <string.h>
#include <time.h>
#include <io.h>
#include <conio.h>
#include <pthread.h>
#pragma comment(lib,"ws2_32.lib")
#pragma comment(lib, "pthreadVC2.lib")

/* if it needs more clients to connected, add this */
#define MAXCLIENT 12


count=1; /* 默认置1是因为总有一个listening socket: sockfd[0] */
sockfd[1000]={0};
sockaddr_len=0;
WSADATA wsaData;	/* windows socket stuff */

struct sockaddr_in client_addr;	/* socket stuff */
struct sockaddr_in serv_addr;
pthread_mutex_t lock;/* 用于独占的访问count与sockfd数组 */

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
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
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

	WSAStartup(MAKEWORD(2,2),&wsaData);	/* windows socket init ... */
	sockaddr_len=sizeof(struct sockaddr);
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
	serv_addr.sin_port=htons(60502);
	sockfd[0]=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);

	system("color 30");	/* call DOS API */
	system("title Server");
	system("cls");
	printf("Welcome to server??/n");

	bind(sockfd[0],(struct sockaddr*)&serv_addr,sockaddr_len);
	listen(sockfd[0],10);

	pthread_mutex_init(&lock,NULL);

	for (i = 0; i < MAXCLIENT; i++) {
		pthread_create(&pids[i], NULL, (void *)thread_run, NULL);
	}
	
	for (i = 0; i < MAXCLIENT; i++) {
		pthread_join(pids[i], NULL);
	}
	
	closesocket(sockfd[0]);
	WSACleanup();
	getch();	/* wait for a key to input, like pause */
	return 0;
}
