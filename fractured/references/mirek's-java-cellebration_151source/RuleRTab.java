// Mirek's Java Cellebration
// http://www.mirekw.com
//
// Rules tables

import java.util.StringTokenizer;

public class RuleRTab {
	public int iNghTyp; // neighbourhood type, NGHTYP_MOOR or NGHTYP_NEUM
	public boolean fCtrCell; // use the center cell?
	public boolean fAll1Fire; // all from bitplane 1 can fire
	public int iClo; // count of states
	public int table[][] = new int[MJBoard.MAX_CLO + 1][10]; // rules table

	// ----------------------------------------------------------------
	public RuleRTab() {
		ResetToDefaults();
	}

	// ----------------------------------------------------------------
	// Set default parameters
	public void ResetToDefaults() {
		int iS, iN;
		iNghTyp = MJRules.NGHTYP_MOOR; // neighbourhood type
		fCtrCell = true; // use the center cell
		fAll1Fire = false; // all from bitplane 1 cannot fire

		for (iS = 0; iS <= MJBoard.MAX_CLO; iS++)
			// for all states
			for (iN = 0; iN <= 9; iN++)
				// for all totals of neighbours
				table[iS][iN] = 0;
	}

	// ----------------------------------------------------------------
	// Parse the rule string
	public void InitFromString(String sStr) {
		int i_Stt, i_Ngh, iNum, iTmp;
		StringTokenizer st;
		String sTok;
		ResetToDefaults();

		if (sStr.length() > 6) {
			iNum = 0;
			st = new StringTokenizer(sStr, " ,", true);
			while (st.hasMoreTokens()) {
				sTok = st.nextToken();
				if (sTok.compareTo(",") != 0) {
					iNum++;
					iTmp = Integer.valueOf(sTok).intValue();
					switch (iNum) {
					case 1: // the neighbourhood type
						if (iTmp == 2)
							iNghTyp = MJRules.NGHTYP_NEUM; // Moore neighbourhood
						else
							iNghTyp = MJRules.NGHTYP_MOOR; // von Neumann neighbourhood
						break;
					case 2: // the center cell flag
						fCtrCell = (iTmp == 1); // use the center cell
						break;
					case 3: // all from bitplane 1 can fire
						fAll1Fire = (iTmp == 1); // Rules table - all from bitplane 1 can fire
						break;
					default: // the rule follows
						if (iTmp < 0)
							iTmp = 0;
						if (iTmp > MJBoard.MAX_CLO)
							iTmp = MJBoard.MAX_CLO;
						i_Stt = (iNum - 4) / 10;
						i_Ngh = (iNum - 4) % 10;
						table[i_Stt][i_Ngh] = iTmp;
						iClo = i_Stt + 2;
						break;
					}
				}
			}
		}
		Validate(); // now correct parameters
	}

	// ----------------------------------------------------------------
	// Create the Rules table string
	public String GetAsString() {
		String sBff = "";

		// correct parameters first
		Validate();

		// make the string
		if (iNghTyp == MJRules.NGHTYP_NEUM) // von Neumann neighbourhood
			sBff = "2";
		else
			// Moore neighbourhood
			sBff = "1";

		if (fCtrCell) // include the center cell
			sBff = sBff + ",1";
		else
			sBff = sBff + ",0";

		if (fAll1Fire) // all cells from bitplane 1 can fire
			sBff = sBff + ",1";
		else
			sBff = sBff + ",0";

		int i_Stt, i_Ngh, iTmp;
		for (i_Stt = 0; i_Stt <= MJBoard.MAX_CLO; i_Stt++) // for all states
		{
			for (i_Ngh = 0; i_Ngh <= 9; i_Ngh++) // for all totals of neighbours
			{
				iTmp = table[i_Stt][i_Ngh];
				if (iTmp < 0)
					iTmp = 0;
				if (iTmp > MJBoard.MAX_CLO)
					iTmp = MJBoard.MAX_CLO;
				sBff = sBff + "," + String.valueOf(iTmp);
			}
		}

		// remove trailing 0's
		while ((sBff.length() > 2) && (sBff.endsWith(",0"))) {
			sBff = sBff.substring(0, sBff.length() - 3);
		}

		return sBff;
	}

	// ----------------------------------------------------------------
	// Check the validity of the Rules table parameters, correct
	// them if necessary.
	public void Validate() {
		table[0][0] = 0; // safety-valve

		if (iClo < 2)
			iClo = 2;
		else if (iClo > MJBoard.MAX_CLO)
			iClo = MJBoard.MAX_CLO;
	}

	// ----------------------------------------------------------------
	// Perform one pass of the rule
	public int OnePass(int sizX, int sizY, boolean isWrap, int ColoringMethod,
			short crrState[][], short tmpState[][], MJBoard mjb) {
		short bOldVal, bNewVal;
		int modCnt = 0;
		int i, j, iCnt;
		int lurd[] = new int[4]; // 0-left, 1-up, 2-right, 3-down
		int rtMask;
		boolean fMoore = (iNghTyp == MJRules.NGHTYP_MOOR); // Moore neighbourhood? Else von Neumann.

		if (fAll1Fire) // full bitplane 1 fires
			rtMask = 1; // any with bit 1 on can do
		else
			rtMask = 0xFF; // only state 1

		for (i = 0; i < sizX; ++i) {
			// determine left and right cells
			lurd[0] = (i > 0) ? i - 1 : (isWrap) ? sizX - 1 : sizX;
			lurd[2] = (i < sizX - 1) ? i + 1 : (isWrap) ? 0 : sizX;
			for (j = 0; j < sizY; ++j) {
				// determine up and down cells
				lurd[1] = (j > 0) ? j - 1 : (isWrap) ? sizY - 1 : sizY;
				lurd[3] = (j < sizY - 1) ? j + 1 : (isWrap) ? 0 : sizY;
				bOldVal = crrState[i][j];

				iCnt = 0; // count of neighbours
				if (fMoore && ((crrState[lurd[0]][lurd[1]] & rtMask) == 1))
					iCnt++;
				if ((crrState[lurd[0]][j] & rtMask) == 1)
					iCnt++;
				if (fMoore && ((crrState[lurd[0]][lurd[3]] & rtMask) == 1))
					iCnt++;

				if ((crrState[i][lurd[1]] & rtMask) == 1)
					iCnt++;
				if (fCtrCell && ((crrState[i][j] & rtMask) == 1))
					iCnt++;
				if ((crrState[i][lurd[3]] & rtMask) == 1)
					iCnt++;

				if (fMoore && ((crrState[lurd[2]][lurd[1]] & rtMask) == 1))
					iCnt++;
				if ((crrState[lurd[2]][j] & rtMask) == 1)
					iCnt++;
				if (fMoore && ((crrState[lurd[2]][lurd[3]] & rtMask) == 1))
					iCnt++;

				bNewVal = (short) table[bOldVal][iCnt]; // new cell status

				tmpState[i][j] = bNewVal;
				if (bNewVal != bOldVal) {
					modCnt++; // one more modified cell
				}
			}
		}

		return modCnt;
	}
	// ----------------------------------------------------------------
}