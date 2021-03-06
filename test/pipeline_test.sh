#!/bin/bash
INPUT='./test/data/test.vcf'
PED='./test/data/test.ped'
HPO='HP:0004383'

ACTUAL_VCF='./test/output/test_output.vcf'
ACTUAL_HTML='./test/output/test_output.html'
EXPECTED_VCF='./test/data/expected.vcf'
EXPECTED_HTML='./test/data/expected.html'
EXPECTED_NR_OF_HEADERS=47
LOG='./test/output/test_output.log'

echo -e "Test started..."

bash ./pipeline.sh -i "${INPUT}" -o "${ACTUAL_VCF}.gz" -p "${PED}" -t "${HPO}" -f &> "${LOG}"

if [ $? -eq 0 ]
then
  echo -e "\e[32mPipeline ran succesfully.  \e[39m"
else
  echo -e "\e[31mAn error occured while running the pipeline, see './test/output/test_output.log' for more details.  \e[39m"
  echo -e "\e[31mTest should run from the 'main' pipeline folder 'bash test/pipeline_test.sh' \e[39m"
  exit 1
fi

if [ -f ${ACTUAL_VCF} ]
then
  rm ${ACTUAL_VCF}
fi
gunzip ${ACTUAL_VCF}.gz

HEADERS_COUNT=$(grep '^##' ${ACTUAL_VCF} | wc -l)
if [ ${EXPECTED_NR_OF_HEADERS} != ${HEADERS_COUNT} ]
then
  echo -e "\e[31mNr of vcf headers test failed: expected: ${EXPECTED_NR_OF_HEADERS} got: ${HEADERS_COUNT} \e[39m"
  FAILED=1
else
    echo -e "\e[32mNr of vcf headers test passed. \e[39m"
fi

#remove parts that differ per run or environment before comparing output.
sed -i '/^##VEP/d' ${ACTUAL_VCF}
sed -i '/^##bcftools/d' ${ACTUAL_VCF}
sed -i '/^##contig/d' ${ACTUAL_VCF}
sed -i '/^##fileDate/d' ${ACTUAL_VCF}
sed -i '/^##VIP/d' ${ACTUAL_VCF}
sed -i 's/"CAPICE pathogenicity prediction.*/"CAPICE pathogenicity prediction"/g' ${ACTUAL_VCF}

VCF_DIFF=$(diff $ACTUAL_VCF $EXPECTED_VCF)
if [ "$VCF_DIFF" != "" ] 
then
  echo -e "\e[31mvcf file test failed, output file differs from expected: \e[39m"
  echo "---BEGIN diff---"
	echo $VCF_DIFF
	echo "---END diff---"
	FAILED=1
else
    echo -e "\e[32mvcf file test passed. \e[39m"
fi

sed -i 's/"args":"-i.*step2_capice/REMOVE_PATH_DEPENDENT_VALUES/g' test/output/test_output.html

REPORT_DIFF=$(diff $ACTUAL_HTML $EXPECTED_HTML)
if [ "$REPORT_DIFF" != "" ] 
then
    	echo -e "\e[31report file test failed, output file differs from expected, \e[39m"
  echo "run 'diff $ACTUAL_HTML $EXPECTED_HTML}' for more information."
  FAILED=1
else
    echo -e "\e[32mreport file test passed. \e[39m"
fi

echo -e "Test finished..."

if [ "${FAILED}" == 1 ]
then
  exit 1
else
  exit 0
fi