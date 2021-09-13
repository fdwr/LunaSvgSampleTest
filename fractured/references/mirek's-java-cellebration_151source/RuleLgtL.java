// Mirek's Java Cellebration
// http://www.mirekw.com
//
// Larger than Life rules

import java.util.StringTokenizer;

public class RuleLgtL {
	public boolean isHist; // with history?
	public int iClo; // count of states
	public int iRng; // range
	public int iNgh; // neighbourhood type
	public int iSMin, iSMax; // surviving rules
	public int iBMin, iBMax; // birth rules
	public boolean isCentr; // use the center (middle) cell?

	public static final int MAX_RANGE = 10;

	// ----------------------------------------------------------------
	public RuleLgtL() {
		ResetToDefaults();
	}

	// ----------------------------------------------------------------
	// Set default parameters
	public void ResetToDefaults() {
		isHist = false; // with history?
		iClo = 2; // count of colors
		iRng = 5; // range
		iNgh = MJRules.NGHTYP_MOOR; // neighbourhood type
		iSMin = 34;
		iSMax = 58; // surviving rules
		iBMin = 34;
		iBMax = 45; // birth rules
		isCentr = true; // use the center (middle) cell?
	}

	// ----------------------------------------------------------------
	// Parse the rule string
	// Example: "R3,C0,M1,S34..58,B34..45,NM"
	public void InitFromString(String sStr) {
		StringTokenizer st;
		String sTok, sBff;
		int i, iTmp;
		ResetToDefaults();

		st = new StringTokenizer(sStr, ",", true);
		while (st.hasMoreTokens()) {
			sTok = st.nextToken().toUpperCase();
			sTok = sTok.trim();
			//System.out.println(sTok);

			if (sTok.startsWith("R")) // range
			{
				iRng = Integer.valueOf(sTok.substring(1)).intValue();
			} else if (sTok.startsWith("C")) // states (history)
			{
				i = Integer.valueOf(sTok.substring(1)).intValue();
				if (i >= 3) {
					isHist = true; // history, get the states count
					iClo = i;
				} else
					isHist = false; // states count is meaningless
			} else if (sTok.startsWith("M")) // center cell?
			{
				isCentr = (Integer.valueOf(sTok.substring(1)).intValue() > 0);
			} else if (sTok.startsWith("NM")) // Moore neighbourhood
			{
				iNgh = MJRules.NGHTYP_MOOR;
			} else if (sTok.startsWith("NN")) // von Neumann neighbourhood
			{
				iNgh = MJRules.NGHTYP_NEUM;
			} else if (sTok.startsWith("S")) // surviving rules
			{
				if (sTok.length() >= 4) {
					iTmp = sTok.indexOf("..");
					if (iTmp >= 0) {
						sBff = sTok.substring(1, iTmp);
						iSMin = Integer.valueOf(sBff).intValue();
						sBff = sTok.substring(iTmp + 2);
						iSMax = Integer.valueOf(sBff).intValue();
					}
				}
			} else if (sTok.startsWith("B")) // birth rules
			{
				if (sTok.length() >= 4) {
					iTmp = sTok.indexOf("..");
					if (iTmp >= 0) {
						iBMin = Integer.valueOf(sTok.substring(1, iTmp))
								.intValue();
						iBMax = Integer.valueOf(sTok.substring(iTmp + 2))
								.intValue();
					}
				}
			}
		}

		// no more tokens
		Validate(); // now correct parameters
	}

	// ----------------------------------------------------------------
	//
	public void InitFromPrm(boolean is_Hist, int i_Clo, int i_Rng, int i_Ngh,
			int i_SMin, int i_SMax, int i_BMin, int i_BMax, boolean is_Centr) {
		isHist = is_Hist; // with history?
		iClo = i_Clo; // count of colors
		iRng = i_Rng; // range
		iNgh = i_Ngh; // neighbourhood type
		iSMin = i_SMin;
		iSMax = i_SMax; // surviving rules
		iBMin = i_BMin;
		iBMax = i_BMax; // birth rules
		isCentr = is_Centr; // use the center (middle) cell?

		Validate(); // now correct parameters
	}

	// ----------------------------------------------------------------
	// Create the rule string
	// Example: "R3,C0,M1,S34..58,B34..45,NM"
	public String GetAsString() {
		String sBff;
		int ih;

		// correct parameters first
		Validate();

		// range
		sBff = "R" + String.valueOf(iRng);

		// states
		if (isHist)
			ih = iClo;
		else
			ih = 0;
		sBff = sBff + ",C" + String.valueOf(ih);

		// center cell
		if (isCentr)
			sBff = sBff + ",M1";
		else
			sBff = sBff + ",M0";

		// S rules
		sBff = sBff + ",S" + String.valueOf(iSMin) + ".."
				+ String.valueOf(iSMax);

		// B rules
		sBff = sBff + ",B" + String.valueOf(iBMin) + ".."
				+ String.valueOf(iBMax);

		// neighbourhood
		if (iNgh == MJRules.NGHTYP_NEUM) // von Neumann neighbourhood
			sBff = sBff + ",NN";
		else
			// Moore neighbourhood
			sBff = sBff + ",NM";

		return sBff;
	}

	// ----------------------------------------------------------------
	// Check the validity of the parameters, correct them if necessary.
	public void Validate() {
		int i, iMax;

		if (iClo < 2)
			iClo = 2;
		else if (iClo > MJBoard.MAX_CLO)
			iClo = MJBoard.MAX_CLO;

		if (iRng < 1)
			iRng = 1;
		else if (iRng > MAX_RANGE)
			iRng = MAX_RANGE;

		if (iNgh != MJRules.NGHTYP_NEUM)
			iNgh = MJRules.NGHTYP_MOOR; // default - Moore neighbourhood

		if (isCentr)
			iMax = 1;
		else
			iMax = 0;
		for (i = 1; i <= iRng; i++)
			// calculate the max. threshold
			iMax = iMax + i * 8;

		iSMin = BoundInt(1, iSMin, iMax);
		iSMax = BoundInt(1, iSMax, iMax);
		iBMin = BoundInt(1, iBMin, iMax);
		iBMax = BoundInt(1, iBMax, iMax);
	}

	// ----------------------------------------------------------------
	private int BoundInt(int iMin, int iVal, int iMax) {
		if (iVal < iMin)
			return iMin;
		if (iVal > iMax)
			return iMax;
		return iVal;
	}

	// ----------------------------------------------------------------
	// Perform one pass of the rule
	public int OnePass(int sizX, int sizY, boolean isWrap, int ColoringMethod,
			short crrState[][], short tmpState[][], MJBoard mjb) {
		short bOldVal, bNewVal;
		int modCnt = 0;
		int i, j, iCnt;
		int lurd[] = new int[4]; // 0-left, 1-up, 2-right, 3-down
		int xVector[] = new int[21]; // 0..9, 10, 11..20
		int yVector[] = new int[21]; // 0..9, 10, 11..20
		int colL, colR, rowT, rowB;
		int ic, ir, iTmp;
		int iTmpC, iTmpR, iTmpBlobC, iTmpBlobR;
		int ctrCol, ctrRow;
		boolean fMoore = (iNgh == MJRules.NGHTYP_MOOR); // Moore neighbourhood? Else von Neumann.

		for (i = 0; i < sizX; i++) {
			for (j = 0; j < sizY; j++) {
				// prepare vectors holding proper rows and columns
				// of the n-range neighbourhood
				xVector[10] = i;
				yVector[10] = j;
				for (iTmp = 1; iTmp <= iRng; iTmp++) {
					colL = i - iTmp;
					if (colL >= 0)
						xVector[10 - iTmp] = colL;
					else
						xVector[10 - iTmp] = sizX + colL;

					colR = i + iTmp;
					if (colR < sizX)
						xVector[10 + iTmp] = colR;
					else
						xVector[10 + iTmp] = colR - sizX;

					rowT = j - iTmp;
					if (rowT >= 0)
						yVector[10 - iTmp] = rowT;
					else
						yVector[10 - iTmp] = sizY + rowT;

					rowB = j + iTmp;
					if (rowB < sizY)
						yVector[10 + iTmp] = rowB;
					else
						yVector[10 + iTmp] = rowB - sizY;
				}
				bOldVal = crrState[i][j];
				bNewVal = bOldVal; // default - no change
				if (bNewVal >= iClo)
					bNewVal = (short) (iClo - 1);

				iCnt = 0; // count of firing neighbours
				if (isHist) {
					if (bOldVal <= 1) // can survive or be born
					{
						for (ic = 10 - iRng; ic <= 10 + iRng; ic++) {
							for (ir = 10 - iRng; ir <= 10 + iRng; ir++) {
								if ((isCentr) || (ic != i) || (ir != j)) {
									if ((fMoore)
											|| ((Math.abs(ic - 10) + Math
													.abs(ir - 10)) <= iRng)) {
										if (crrState[xVector[ic]][yVector[ir]] == 1) {
											iCnt++;
										}
									}
								}
							}
						}
						// determine the new cell state
						if (bOldVal == 0) // was dead
						{
							if ((iCnt >= iBMin) && (iCnt <= iBMax)) // rules for birth
								bNewVal = 1; // birth
						} else // was 1 - alive
						{
							if ((iCnt >= iSMin) && (iCnt <= iSMax)) // rules for surviving
							{
								bNewVal = 1;
							} else // isolation or overpopulation
							{
								if (bOldVal < (iClo - 1))
									bNewVal = (short) (bOldVal + 1); // getting older...
								else
									bNewVal = 0; // bye, bye!
							}
						}
					} else // was older than 1
					{
						if (bOldVal < (iClo - 1))
							bNewVal = (short) (bOldVal + 1); // getting older...
						else
							bNewVal = 0; // bye, bye!
					}
				} else // no history
				{
					for (ic = 10 - iRng; ic <= 10 + iRng; ic++) {
						for (ir = 10 - iRng; ir <= 10 + iRng; ir++) {
							if ((isCentr) || (ic != i) || (ir != j)) {
								if ((fMoore)
										|| ((Math.abs(ic - 10) + Math
												.abs(ir - 10)) <= iRng)) {
									if (crrState[xVector[ic]][yVector[ir]] != 0) {
										iCnt++;
									}
								}
							}
						}
					}
					// determine the cell status
					if (bOldVal == 0) // was dead
					{
						if ((iCnt >= iBMin) && (iCnt <= iBMax)) // rules for birth
							if (ColoringMethod == 1) // standard
								bNewVal = 1; // birth
							else
								bNewVal = (short) (mjb.Cycle
										% (mjb.StatesCount - 1) + 1); // birth
					} else // was alive
					{
						if ((iCnt >= iSMin) && (iCnt <= iSMax)) // rules for surviving
						{
							if (ColoringMethod == 1) // standard
							{
								if (bOldVal < (mjb.StatesCount - 1))
									bNewVal = (short) (bOldVal + 1); // getting older...
								else
									bNewVal = (short) (mjb.StatesCount - 1);
							} else {
								// alternate coloring - cells remain not changed
							}
						} else
							bNewVal = 0; // isolation or overpopulation
					}
				}
				tmpState[i][j] = bNewVal;
				if (bNewVal != bOldVal) // change detected
				{
					modCnt++; // one more modified cell
				}
			} // for j
		} // for i

		return modCnt;
	}
	// ----------------------------------------------------------------
}