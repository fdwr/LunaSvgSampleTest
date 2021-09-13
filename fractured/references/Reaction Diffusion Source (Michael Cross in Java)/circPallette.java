// Sets up circular rainbow pallette for phase plot
public class circPallette extends myPallette {
      
      public circPallette() {
            int i,j;
            double multWide=255./42.;
            double multNarrow=255./41.;
            for(j=0,i=0;i<42;i++,j++) {
                  r[j]=255;
                  g[j]=0;
                  b[j]=(int)(multNarrow*i);
            }
            for(i=0;i<43;i++,j++) {
                  r[j]=255-(int)(multWide*i);
                  g[j]=0;
                  b[j]=255;
            }
            for(i=0;i<43;i++,j++) {
                  r[j]=0;
                  g[j]=(int)(multWide*i);
                  b[j]=255;
            }
            for(i=0;i<43;i++,j++) {
                  r[j]=0;
                  g[j]=255;
                  b[j]=255-(int)(multWide*i);
            }                        
            for(i=0;i<43;i++,j++) {
                  r[j]=(int)(multWide*i);
                  g[j]=255;
                  b[j]=0;
            }      
            for(i=0;i<42;i++,j++) {
                  r[j]=255;
                  g[j]=255-(int)(multNarrow*i);
                  b[j]=0;
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
            

