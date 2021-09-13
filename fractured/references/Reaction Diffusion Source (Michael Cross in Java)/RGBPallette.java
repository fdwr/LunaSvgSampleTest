// Sets up circular rainbow pallette for phase plot
public class RGBPallette extends myPallette {
      
      public RGBPallette() {
            int i,j;
            for(j=0,i=0;i<128;i++,j++) {
                  b[j]=255-2*i*i/128;
                  g[j]=255-2*(128-i)*(128-i)/128;
                  r[j]=0;
            }
            for(i=0;i<128;i++,j++) {
                  b[j]=0;
                  g[j]=255-2*(i)*(i)/128;
                  r[j]=255-2*(128-i)*(128-i)/128;
            }
            
            // Check range for mistakes!
            for(i=0;i<=255;i++) {
               if(r[i]<0) r[i]=0;
               if(g[i]<0) g[i]=0;
               if(b[i]<0) b[i]=0;
               if(r[i]>255) r[i]=255;
               if(g[i]>255) g[i]=255;               
               if(b[i]>255) b[i]=255;
            }    
      }
}                  
            

