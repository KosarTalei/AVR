#include <stdio.h>
#include <time.h>

double AreaC(int n, double list[n][2]);
double area(int n, double[n][2]);   //area.asm

int main(){
    int n;
    scanf("%d",&n);
    double a[n][2];

    for( int i=0;i<n;i++)
        scanf("%f%f",&a[i][0],&a[i][1]);

    struct timespec start,stop;
    clock_gettime(CLOCK_REALTIME,&start);

    double res = area(n,a);

    clock_gettime(CLOCK_REALTIME,&stop);
    printf("%f\n",res);
    printf("%d\n",stop.tv_nsec - start.tv_nsec);
    return 0;
}
double AreaC(int n, double list[n][2]){
    double area = 0;
    for(int i=0;i<n;i++)
        area += list[i][0] * list[(i+1)%n][1] - list[i][1] * list[(i+1)%n][0];
    return area >0 ? area/2 : -area/2;
}
