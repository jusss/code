#include <stdio.h>
#include <malloc.h>
int compare_array(int n,int offset,int *array)
{
	int return_value = 0; 
	for (;offset>=0;offset--) {
		if (array[offset] == n) {return_value = 1; break;}
	}
	if (return_value == 1) return 0;
	else return 1;
}
int main()
{
	int *release_sockfd = (int *)malloc(1000);
	int release_number = 3;
	int a=3,b=0;
	release_sockfd[0]=3;
	release_sockfd[1]=39;
	release_sockfd[2]=32;
	release_sockfd[3]=33;
	b=compare_array(a,release_number,release_sockfd);
	printf("%d\n",b);
}
