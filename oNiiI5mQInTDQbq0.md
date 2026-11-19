I modelled GAPRN (Global Anomalous Phenomena Research Network) the way MUFON (Mutual UFO Network) investigators work - each case gets a list of candidate theories, experts review the evidence, and a director approves the outcome. I only included what a requirement needs, based my choices on my sources, kept history as new rows, and calculate credibility instead of storing it. To keep the model simple, (and because I wanted to converve time) a few rules like history being in time order, closing only on an approved outcome, no loops in the location tree are left to the application

# Models
- Staff:
  All people working for GAPRN - such as investigators, experts, laboratory staff, and supervisors - are stored in this single table. Access permissions are determined by a person's role/qualification rather than being assigned separately to specific job positions. That's because the same person can have different roles on different cases - serving as an investigator in one case while acting as an expert reviewer in another

  Each staff member has one login account, therefore, their email address must be unique. Records of staff who have left the organization are not deleted but are marked using the leftOn (departure date) field. That way their names stay linked to old cases, outcomes and handovers

- Role:
  Roles such as supervisor, field investigator, expert, and researcher are stored in a separate table, allowing for the addition of new roles without requiring changes to the system design

- Witness:
  As members of the public, witnesses are managed separately from staff and do not have system login access. Since a witness can provide testimony for multiple cases, their contact information is stored only once

  Witnesses can choose not to provide their names, therefore, the full name field can be left blank. An is anonymous flag is used to identify witnesses whose names must not appear in any content published by GAPRN

- Location:
  All location related information required by the system - including countries, regions, cities, incident sites, as well as the buildings, rooms, and lockers where evidence is stored - is stored in one table. Each location is assigned a type and geographic coordinates (latitude and longitude), for regions, the coordinates represent their central point

  Each location record contains a parentId field that points to another record within the same Location table. For example, Locker 3 might point to evidence room, which points to headquarters building, which points to Toronto. Countries have no parent, so their parentId field is left null. I set it up this way because places don't all nest the same depth - a location might sit straight under a region with no city in between. To query all cases within a specific region, you would start from that region and follow the parent links downward

  Locations sharing the same parent cannot have identical names. The application must ensure that no cycles exist within this tree structure as a location cannot be inside one of its own children

- CaseFile:
  A case is a reported incident investigated by GAPRN. The brief uses both "case" and "investigation". Since each case is only investigated once, I treated them as the same thing. The table is named CaseFile because CASE is a reserved keyword in SQL Server. Each case is assigned a unique identifier (like GAPRN-2026-0042), which is also printed on evidence labels

  Each case is associated with a primary category and a location. If the report is vague, the location information can be broad, which indicates a general region rather than a specific site. If a witness does not specify the time of the incident, the corresponding field can be left blank. All timestamps are stored in UTC to ensure that records from different countries can be sorted correctly

- Theory:
  A theory is a possible explanation - such as a weather balloon, a satellite, a hoax, or something else that has yet to be explained. Since most cases turn out to have ordinary causes, both ordinary and unusual explanations are categorized as theories. Each theory is stored only once and can be linked to many cases, so you can see every case linked to a specific theory

- Outcome:
  An outcome is the final decision for a given case, which can be classified as: unknown, identified, hoax, or insufficient data. Outcomes are proposed by an investigator and approved by a director, because both MUFON and AARO (All-domain Anomaly Resolution Office) want a second person to confirm it. It's a weak entity - its primary key is the case plus an outcome number - since an outcome can't exist without its case. If a case is reopened and closed again, a second outcome is generated, ensuring that the previous outcome is preserved

  Only outcomes classified as identified or hoax specify a theory, and this theory must be one of the candidate theories associated with the case. The person approving must be different from the person who proposed the outcome and must be a director on the date of approval

- StatusChange:
  Whenever a case moves through the workflow (like a submission, assignment, completion, return, or closure), the system creates a new record, so the case's history is kept. It's a weak entity - its primary key is the case plus a sequence number. A case's status and its outcome are stored separately (I based this off of the approach used in the MUFON system), the status reflects the current stage of the case within the workflow, while the outcome indicates the conclusion reached. When the status is closed, the record points to the outcome that led to the case's closure

  Every case begins with an submitted record, and this status can't come up again at any later stage. Once a record is created, it cannot be edited or deleted, any corrections must be made by adding a new record. To reopen a case, a new assigned record must be added

- Evidence:
  Each item of evidence (photograph, video, audio recording, document, physical specimen, or field record) is associated with a case. It is a weak entity - its primary key is composed of the case and an item number, which matches how evidence bags are labelled (case number + item number). For digital evidence, the file's storage location must be recorded, for physical evidence, the quantity must be documented
  
- EvidenceHandover:
  This represents the chain of custody. Each entry records who received it, when, the storage location, and the type of handover (collection, transfer, transport to a laboratory, storage, return to owner, or destruction). I based the format of this record off of the NIST (National Institute of Standards and Technology) specifications for chain of custody forms. It is a weak entity under the Evidence entity, with a primary key composed of the evidence item and a sequence number. The current holder of a piece of evidence is the person identified in the final entry for that item

  The first entry must be collected, and this type cannot reappear in any later entries. The record does not store the person performing the return, as this information is linked to the holder identified in the previous entry. Once an item of evidence is returned to its owner or destroyed, it is no longer held by GAPRN

- Equipment:
  Items such as cameras, EMF (electromagnetic field) meters, and drones are labeled with asset tags, model numbers, and serial numbers when in storage. For equipment that is no longer in use, the system records a retirement date rather than deleting the record, so its borrowing history is kept

  Retired equipment cannot be checked out

- Review:
  A review is an examination of a piece of evidence by an expert using methods (such as photo analysis, radar analysis, or laboratory testing). Each review assigns a reliability score - ranging from 0 to 100 - to the evidence and documents the expert's conclusions. Laboratory analysis is any review that uses laboratory testing methods. Only staff qualified in a method are allowed to do reviews using that method

  An expert can conduct multiple reviews of the same piece of evidence, and all records are kept. To ensure data integrity, only the most recent review - for a given piece of evidence, expert, and method - is considered, so repeated reviews are not double counted

- Project:
  Research projects, field investigations, outreach initiatives, and training programs are documented, including the project type, the lead (primary staff member), and the start and end dates

  Each project has exactly one lead. If the end date is left blank, the project is ongoing

- Publication:
  Publications produced by GAPRN. A publication can come from a research project

  A publication is associated with at most one project. Some publications can not come from any project, in such cases, the project field can be left blank

- StaffRole:
  A staff member can hold multiple roles, and each role can be held by multiple staff members - this table handles that M:N (many to many) relationship. The table records the date a role was granted, if a role has ended, the date it was revoked is also recorded

  Roles are marked as revoked via a date rather than deleted, since approvals made by a supervisor still need to link to a real role

- StaffQualification:
  A staff member can be qualified in multiple assessment methods, and each assessment method can be performed by multiple staff members, therefore, each qualification is recorded as a separate entry. Any assessment activity must match a qualification record, ensuring that only staff members with the appropriate qualification are allowed to use a given method to assess evidence

- Assignment:
  Staff members can be involved in multiple cases, and a case can involve multiple staff members - this table handles that M:N relationship. Each assignment includes a start time and an end time, and one person can be designated as the lead

  A case can have only one lead at any time, a staff member cannot be assigned to the same case more than once for the same time period. Since the start time is part of the primary key, a person can be reassigned to a case at a later date after having left it

- Statement:
  Witnesses can provide statements for multiple cases, and a case can involve multiple witnesses - this table handles that M:N relationship. The table stores statements provided in the witnesses' own words and includes a credibility rating, which I based off of the scale used by Project Blue Book: excellent, good, doubtful, or poor

  Each witness provides only one statement per case - any later interviews are stored as evidence. If a statement is too brief to allow for a meaningful assessment, it can be left without a rating (I based this off of the practice established by Project Blue Book)

- CaseTheory:
  A case can be associated with multiple candidate theories, and a theory can apply to multiple cases - this table handles that M:N relationship. It records which person proposed a theory for a given case, as well as the time at which it was proposed. MUFON calls this the investigator candidate theory list

- EquipmentLoan:
  A piece of equipment can be loaned out multiple times, and a staff member can borrow multiple items - this table handles that M:N relationship. Each loan record includes: the person who borrowed the item, the date/time it was loaned, the date/time it was returned, and optionally, the case associated with the equipment. If a loan record has no return date, the equipment is currently on loan

  A piece of equipment can be loaned to only one person at any time

- LKUP_Category:
  Every case must be assigned a category from this list (e.g UFO/UAP (unidentified flying object / unidentified anomalous phenomena) sightings, mysterious creatures, paranormal phenomena, disappearances). Adding a new category is just a new row, so new types of investigation are easy to add

  Each category can include a parentId that points to another category within the same table - the category lights in the sky could be nested under aerial phenomena. Top level categories have no parent. That way categories can be grouped without a separate table for each level

- LKUP_LocationKind:
  Types of locations within the location hierarchy, including country, region, city, site, building, room, and container

- LKUP_CaseStatus:
  Possible states a case can go through within a workflow, including submitted, assigned, completed, returned, and closed. I based these statuses off of MUFON's case management system

- LKUP_OutcomeKind:
  Possible conclusions for a case, including unknown (aerial), unknown (other), identified, hoax, and insufficient data. I classified these based off of the outcomes used by MUFON. Archived cases are considered closed cases with insufficient data, therefore, a separate archived status is not required

- LKUP_TheoryKind:
  Categories of theories, including natural phenomena, man made objects, hoaxes, psychological factors, and anomalous phenomena

  (Similar to category field) Theory type includes a parentId field that points to another record within the same table - for example, both satellite and balloon fall under the category of man made objects. That way theories can be grouped as broadly or as specifically as needed

- LKUP_EvidenceKind:
  Types of evidence listed in the briefing, including photographs, videos, audio recordings, documents, physical samples, and field records

- LKUP_ReviewMethod:
  Methods available to experts for reviewing evidence, such as photographic analysis, radar analysis, audio analysis, and laboratory testing. Since this same list is used to define staff qualifications, each review method is specific

- LKUP_HandoverKind:
  Types of records within the chain of custody for evidence, including a collection, transfer, submission to a laboratory, storage, return to owner, and destruction. I classified these based off of the definitions in the NIST documentation

- LKUP_EquipmentKind:
  The types of equipment owned by GAPRN, such as cameras, thermal imagers, drones, EMF meters, and Geiger counters

- LKUP_ProjectKind:
  Categories of projects, including research, investigations, outreach, and training

- LKUP_Reliability:
  The four reliability ratings used by Project Blue Book, those ratings are excellent (100), good (75), questionable (50), and poor (25). I am storing these values in a table to ensure that any adjustments to the scoring system do not require changes to database queries

  The credibility of a case is calculated based on its individual ratings rather than being stored as a static value, which prevents data from becoming outdated. The score is the average of the initial statement rating and the latest assessment rating, plus two additional questionable ratings. I did this so a case with one excellent rating doesn't rank higher than one with lots of good ratings - a case with one excellent rating would receive a score of 66.7, where a case with ten good ratings would receive a score of 70.8
