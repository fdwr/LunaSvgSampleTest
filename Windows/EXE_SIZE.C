unsigned int BaseGetIntendedSize(void)
{
	char* pBase;
	unsigned int nSize,nSectionCount,i;

	pBase=(char*) g_hInstance;

	// Find pointer to IMAGE_NT_HEADERS
	pBase+=((IMAGE_DOS_HEADER*)pBase)->e_lfanew;

	// Get section count
	nSectionCount=((IMAGE_NT_HEADERS*)pBase)->FileHeader.NumberOfSections;

	// Manage to find the "size of headers"
	nSize=((IMAGE_NT_HEADERS*)pBase)->OptionalHeader.SizeOfHeaders;

	// Find first section
	pBase+=sizeof(IMAGE_NT_HEADERS)-(sizeof(IMAGE_DATA_DIRECTORY)*(IMAGE_NUMBEROF_DIRECTORY_ENTRIES-(((IMAGE_NT_HEADERS*)pBase)->OptionalHeader.NumberOfRvaAndSizes)));

	// Iterate all sections and sum their sizes
	for (i=0;i<nSectionCount;i++)
	{
		nSize+=((IMAGE_SECTION_HEADER*)pBase)->SizeOfRawData;
		pBase+=sizeof(IMAGE_SECTION_HEADER);
	}

#ifdef _DEBUG
	// To cover the .pdb file name
	nSize+=0x31;	// Needs to be modified if name changes
#endif

	return nSize;
}

