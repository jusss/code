#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

int count=1;
int sockfd[1000]={0};
int sockaddr_len=0;
	
struct sockaddr_in client_addr;	/* socket stuff */
struct sockaddr_in serv_addr;
pthread_mutex_t lock;	


int *release_sockfd;
int release_number = 0;


int compare_array(int n,int offset,int *array)
{
	int return_value = 0; 
	for (;offset>=0;offset--) {
		if (array[offset] == n) {return_value = 1; break;}
	}
	if (return_value == 1) return 0;
	else return 1;
}

sf0()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
sf1()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
sf2()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
sf3()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
sf4()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
sf5()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
sf6()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}
sf7()	/* #4 add */
{
	int retn_select,retn_recv;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0;
	int sub_count,sec_count;
init:
	retn_select=0;
	retn_recv=0;
	recv_buff0=NULL;
	sub_count=0;
	sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	sleep(1);
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
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);
				release_sockfd[release_number]=sub_count;
				release_number++;
				
				goto init;} /* count=count-1 */
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if ((sec_count != sub_count) && compare_array(sec_count,release_number,release_sockfd)) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

/* ... */
	
main()
{

/* if it needs more clients to connected, add 4 area ,then right */

	pthread_t pid0,pid1,pid2,pid3,pid4,pid5,pid6,pid7;

	sockaddr_len=sizeof(struct sockaddr);
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
	serv_addr.sin_port=htons(30802);
	sockfd[0]=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);

	printf("Welcome to server??/n");
	
	release_sockfd = (int *)malloc(1000);
	
	bind(sockfd[0],(struct sockaddr*)&serv_addr,sockaddr_len);
	listen(sockfd[0],10);

	pthread_mutex_init(&lock,NULL);
loop:
	pthread_create(&pid0,NULL,(void *)&sf0,NULL);	/* #2 add */
	pthread_create(&pid1,NULL,(void *)&sf1,NULL);
	pthread_create(&pid2,NULL,(void *)&sf2,NULL);
	pthread_create(&pid3,NULL,(void *)&sf3,NULL);
	pthread_create(&pid4,NULL,(void *)&sf4,NULL);
	pthread_create(&pid5,NULL,(void *)&sf5,NULL);
	pthread_create(&pid6,NULL,(void *)&sf6,NULL);
	pthread_create(&pid7,NULL,(void *)&sf7,NULL);
		
	pthread_join(pid0,NULL);	/* #3 add */
	pthread_join(pid1,NULL);
	pthread_join(pid2,NULL);
	pthread_join(pid3,NULL);
	pthread_join(pid4,NULL);
	pthread_join(pid5,NULL);
	pthread_join(pid6,NULL);
	pthread_join(pid7,NULL);

	
	count = 1;
	goto loop;

	getch();	/* wait for a key to input, like pause */
	return 0;
}

