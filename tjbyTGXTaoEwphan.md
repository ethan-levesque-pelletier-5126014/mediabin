# Models

- Character:
  Since the same character may appear across multiple products, we maintain a separate data record for each one. This ensures that any necessary corrections to a character's name or description only need to be made in a single location

  Assumption: Character names are unique across all series (IPs)

- Collector:
  Account information is associated with a collector, and every collection is linked to that account

  Assumption: A collector is the user who owns the login account - as such, the email address associated with the account must be unique

- Collection:
  Collectors can group models according to their personal preferences - for example, by creating a category for models intended for tradeS

  Assumption: Each collection has only one owner, and collection names must be unique within a single owner's account. At any given time, an individual mSSodel instance can belong to only one collection. Through these associations, we can view all the models owned by a specific user

- Product:
  Multiple collectors may own different instances of the same product - therefore, they share a common product record, which provides a unified view of information related to that product

  Assumption: All versions of a given product share the same character and classification data, allowing us to link this information just once within the product record

- Variant:
  The same model may appear on different packaging cards, which can affect its value. Using variant as an identifier (key) is not ideal, as it incorporates product-related information

  I'm proposing that every specific model instance should point to a defined variant. When creating a product, we will preemptively add a base variant, ensuring that even if a product has only one version, there is still an object to which it can be linked.

- Attachments:
  The parts list has been moved from the product level to the variant level, as different versions may contain different parts. Attachments are considered weak entities because their pk incorporates information about the variant to which they belong

  My assumption is that each product instance should initially include all the parts specified in its corresponding variant list - by listing each part individually, we can determine whether only one part is missing from a given pair

- Collectible:
  Multiple individuals may own items of the same model - one might be in perfect (brand-new) condition, while another could be missing parts. Each collectible has its own individual record, allowing us to track its specific condition and included accessories

- Classification:
  Attributes such as manufacturer, series (IP), product line, wave, and category are used to group products. These are stored in a single table and distinguished by a type field. New types can be added in the future as needed

  Assumption: Classification items can have a parent (where applicable) - for example, assigning a specific wave to a particular product line

- Grade:
  Grading information is stored as a separate record, enabling us to retrieve the corresponding figures associated with a specific grade and look up their respective prices

  Assumption: The most recent grading record is treated as the current grade. Since the condition of the packaging is also considered part of the grading process, a subsequent packaging grade can overwrite (replace) any previous numerical grade

- Event:
  Processes such as the acquisition, grading, valuation, and sale of a collection item (or a specific copy thereof) require the recording of the item, the date, and other relevant details. Consequently, a unified table-incorporating an event type field-can be used to consolidate these historical records. This functions as a weak entity, as its pk includes the identifier of the collection item (or copy) to which it pertains

  Assumption: Every collection item (or copy) is associated with an acquisition event, for which the date is known. Therefore, this event can be logged at the time the item is added to the database, while fields such as acquisition price and source can be left blank initially

- Media:
  The database stores links pointing to individual photographs or documents

  Assumption: Each photo or document record is linked to a specific collection item (or copy) and can be further associated with a particular event linked to that item. This allows, for example, a receipt to be associated with an acquisition event, or a certificate to be linked to a grading event

- Embedding:
  Vectors representing similar products are positioned close to one another in vector space, which facilitates product recommendations. These vectors are generated using a consistent model to ensure comparability - should the model be updated or changed, the existing vector data can be retained

  Assumption: Given that the primary objective is product recommendation, only one vector per product is required for each model used

- ProductClassification:
  A product can belong to multiple categories, and each category can contain multiple products - this table is used to manage those M:N relationships

  Assumptions: Each product is associated with at most one manufacturer and one franchise. The kind attribute is included in this association table to facilitate database-level validation

- ProductCharacter:
  A product pack can contain multiple characters, and a single character may appear across various product releases - this table handles these M:N relationships. It allows for queries to determine which characters are included in a given product pack, as well as to identify all product releases that feature a specific character

- PriceGuide:
  A guide price refers to the market value of a specific product variant at a given condition grade

  Assumptions: For every combination of variant and condition grade, only one current guide price (CAD$) is maintained. When determining value, the most recent appraisal for the specific physical copy takes precedence - if no such appraisal exists, the value is retrieved from the price guide based on the product's variant and current condition grade. If neither method yields a value, the specific copy is classified as no valuation
  
- CollectibleAccessory:
  This table tracks the accessories associated with a specific instance of a collectible

  Design Assumption: When a collectible instance is added, the system defaults all accessories to an acquired status. If an accessory (defined as part of the collectible's variant) lacks a corresponding record in this table, it is considered missing

- LKUP_ClassificationKind:
  All classifications must be assigned a type selected from this list - this prevents the accidental creation of new types due to spelling errors

- LKUP_AllowedParentKind:
  A product line may contain waves. This table defines which parent-child type combinations are valid. When a classification is added or moved, the system uses a trigger to validate the operation against this list

- LKUP_EventKind:
  All events must be assigned a type from a standardized list (e.g., acquisition, grading, sale, etc.)This ensures that events of the same nature are not categorized differently due to variations in terminology (such as purchase versus buy)

- LKUP_MediaKind:
  Media types are drawn from this list (e.g., photos, receipts, certificates, or documents), ensuring that files of the same type are assigned the same label

- LKUP_GradeScale:
  Each grade is associated with a specific grading scale (e.g., the AFA scale, the C scale, or packaging condition grading), so comparisons are made only within the same grading scale (incase we want to introduce different grading scales - unlikely, but there's very little harm in having support for it)

- LKUP_EmbeddingModel:
  Each model has an expected vector length - the database validates this when saving embedding data
