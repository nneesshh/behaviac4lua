﻿// -------------------------------------------------------------------------------
// THIS FILE IS ORIGINALLY GENERATED BY THE DESIGNER.
// YOU ARE ONLY ALLOWED TO MODIFY CODE BETWEEN '///<<< BEGIN' AND '///<<< END'.
// PLEASE MODIFY AND REGENERETE IT IN THE DESIGNER FOR CLASS/MEMBERS/METHODS, ETC.
// -------------------------------------------------------------------------------

#include "FirstAgent.h"

///<<< BEGIN WRITING YOUR CODE FILE_INIT

///<<< END WRITING YOUR CODE

FirstAgent::FirstAgent()
{
	p1 = 0;
///<<< BEGIN WRITING YOUR CODE CONSTRUCTOR

///<<< END WRITING YOUR CODE
}

FirstAgent::~FirstAgent()
{
///<<< BEGIN WRITING YOUR CODE DESTRUCTOR

///<<< END WRITING YOUR CODE
}

behaviac::EBTStatus FirstAgent::Say(behaviac::string& value, bool isLatent)
{
///<<< BEGIN WRITING YOUR CODE Say
	if (isLatent && behaviac::Workspace::GetInstance()->GetFrameSinceStartup() < 3)
	{
		printf("\n%s [Running]\n\n", value.c_str());

		return behaviac::BT_RUNNING;
	}

	printf("\n%s [Success]\n\n", value.c_str());

	return behaviac::BT_SUCCESS;
///<<< END WRITING YOUR CODE
}


///<<< BEGIN WRITING YOUR CODE FILE_UNINIT

///<<< END WRITING YOUR CODE
