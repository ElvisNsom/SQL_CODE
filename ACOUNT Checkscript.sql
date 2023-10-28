USE [dba_utility]GODECLARE @return_value intEXEC @return_value = [dbo].[getAcctGrpMemrpt]	@acct_name = N'pmmr\cyoung1'SELECT 'Return Value' = @return_valueGO
