// Sets up default grey scale pallette for plotting
public class greyPallette extends myPallette {
          public int[] r,g,b;
          public greyPallette() {
                r = new int[256];
                g = new int[256];
                b = new int[256];
                for(int i=0;i<256;i++) {
                  r[i]=i;
                  g[i]=i;
                  b[i]=i;
                }
          }
}            
