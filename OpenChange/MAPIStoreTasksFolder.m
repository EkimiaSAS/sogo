/* MAPIStoreTasksFolder.m - this file is part of SOGo
 *
 * Copyright (C) 2011 Inverse inc
 *
 * Author: Wolfgang Sourdeau <wsourdeau@inverse.ca>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <NGObjWeb/WOContext+SoObjects.h>
#import <EOControl/EOQualifier.h>
#import <Appointments/SOGoAppointmentFolder.h>
#import <Appointments/SOGoAppointmentFolders.h>
#import <Appointments/SOGoTaskObject.h>

#import "MAPIApplication.h"
#import "MAPIStoreTasksContext.h"
#import "MAPIStoreTasksMessage.h"
#import "MAPIStoreTasksMessageTable.h"

#import "MAPIStoreTasksFolder.h"

static Class MAPIStoreTasksMessageK;

@implementation MAPIStoreTasksFolder

+ (void) initialize
{
  MAPIStoreTasksMessageK = [MAPIStoreTasksMessage class];
}

- (id) initWithURL: (NSURL *) newURL
         inContext: (MAPIStoreContext *) newContext
{
  SOGoUserFolder *userFolder;
  SOGoAppointmentFolders *parentFolder;
  WOContext *woContext;

  if ((self = [super initWithURL: newURL
                       inContext: newContext]))
    {
      woContext = [newContext woContext];
      userFolder = [SOGoUserFolder objectWithName: [newURL user]
                                      inContainer: MAPIApp];
      [parentContainersBag addObject: userFolder];
      [woContext setClientObject: userFolder];

      parentFolder = [userFolder lookupName: @"Calendar"
                                  inContext: woContext
                                    acquire: NO];
      [parentContainersBag addObject: parentFolder];
      [woContext setClientObject: parentFolder];
      
      sogoObject = [parentFolder lookupName: @"personal"
                                  inContext: woContext
                                    acquire: NO];
      [sogoObject retain];
    }

  return self;
}

- (Class) messageClass
{
  return MAPIStoreTasksMessageK;
}

- (MAPIStoreMessageTable *) messageTable
{
  if (!messageTable)
    ASSIGN (messageTable,
            [MAPIStoreTasksMessageTable tableForContainer: self]);

  return messageTable;
}

- (EOQualifier *) componentQualifier
{
  static EOQualifier *componentQualifier = nil;

  /* TODO: we need to support vlist as well */
  if (!componentQualifier)
    componentQualifier
      = [[EOKeyValueQualifier alloc] initWithKey: @"c_component"
				operatorSelector: EOQualifierOperatorEqual
					   value: @"vtodo"];

  return componentQualifier;
}

- (MAPIStoreMessage *) createMessage
{
  MAPIStoreMessage *newMessage;
  SOGoTaskObject *newEntry;
  NSString *name;

  name = [NSString stringWithFormat: @"%@.ics",
                   [SOGoObject globallyUniqueObjectId]];
  newEntry = [SOGoTaskObject objectWithName: name
                                inContainer: sogoObject];
  [newEntry setIsNew: YES];
  newMessage = [MAPIStoreTasksMessage mapiStoreObjectWithSOGoObject: newEntry
                                                        inContainer: self];

  
  return newMessage;
}

@end