////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////
package actionScripts.utils
{
    import actionScripts.factory.FileLocation;
    import actionScripts.valueObjects.FileWrapper;
    import actionScripts.valueObjects.FileWrapper;
    import actionScripts.valueObjects.ProjectReferenceVO;

    import flash.net.SharedObject;
    import actionScripts.valueObjects.ProjectVO;
    import actionScripts.locator.IDEModel;

    public class SharedObjectUtil
	{
        public static function getMoonshineIDEProjectSO(name:String):SharedObject
        {
            var cookie:SharedObject = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
            var model:IDEModel = IDEModel.getInstance();
            if (name.indexOf("projectTree") > -1 && !model.openPreviouslyOpenedProjectBranches) return null;
            if (name.indexOf("projectFiles") > -1 && !model.openPreviouslyOpenedFiles) return null;
            if (name.indexOf("projects") > -1 && !model.openPreviouslyOpenedProjects) return null;
            
            for (var item:Object in cookie.data)
            {
                if (item.indexOf(name) > -1)
                {
                    return cookie;
                }
            }

            return null;
        }

        public static function resetMoonshineIdeProjectSO():void
        {
            var cookie:SharedObject = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
            delete cookie.data["projectTree"];
            for (var item:Object in cookie.data)
            {
                delete cookie.data[item];
            }

            cookie.flush();
        }

		public static function saveProjectTreeItemForOpen(item:Object, propertyNameKey:String,
                                                          propertyNameKeyValue:String):void
		{
            if (!IDEModel.getInstance().openPreviouslyOpenedProjectBranches) return;

			var cookie:Object = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
			if (!cookie.data.projectTree)
			{
				cookie.data.projectTree = [];
			}

			saveProjectItem(item, propertyNameKey, propertyNameKeyValue, "projectTree");
		}
		
		public static function removeProjectTreeItemFromOpenedItems(item:Object, propertyNameKey:String,
                                                                    propertyNameKeyValue:String):void
		{
            if (!IDEModel.getInstance().openPreviouslyOpenedProjectBranches) return;
            
            var cookie:Object = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
            var projectTree:Array = cookie.data.projectTree;
            if (!projectTree) return;

			removeProjectItem(item, propertyNameKey, propertyNameKeyValue, "projectTree");
		}

		public static function saveLocationOfOpenedProjectFile(fileName:String, filePath:String, projectPath:String):void
		{
            var model:IDEModel = IDEModel.getInstance();
            if (!model.openPreviouslyOpenedFiles) return;

            var cookie:Object = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
            var projectLocation:FileLocation = new FileLocation(projectPath);
            var projectReferenceVO: ProjectReferenceVO = new ProjectReferenceVO();
            projectReferenceVO.path = projectPath;
            var fileProjectWrapper:FileWrapper = new FileWrapper(projectLocation, false, projectReferenceVO, false);

			var project:ProjectVO = UtilsCore.getProjectFromProjectFolder(fileProjectWrapper);
			if (!project) return;
			
			var cookieName:String = "projectFiles" + project.name;
            if (!cookie.data[cookieName])
            {
                cookie.data[cookieName] = [];
            }

            saveProjectItem({name: fileName, path: filePath}, "name", "path", cookieName);
		}

		public static function removeLocationOfClosingProjectFile(fileName:String, filePath:String, projectPath:String):void
		{
            var model:IDEModel = IDEModel.getInstance();
            if (!model.openPreviouslyOpenedFiles) return;

            var projectLocation:FileLocation = new FileLocation(projectPath);
            var projectReferenceVO: ProjectReferenceVO = new ProjectReferenceVO();
            projectReferenceVO.path = projectPath;
            var fileProjectWrapper:FileWrapper = new FileWrapper(projectLocation, false, projectReferenceVO, false);

            var project:ProjectVO = UtilsCore.getProjectFromProjectFolder(fileProjectWrapper);
            if (!project) return;

			removeProjectItem({name: fileName, path: filePath}, "name", "path", "projectFiles" + project.name);
		}

        public static function saveProjectForOpen(projectFolderPath:String, projectName:String):void
        {
            var model:IDEModel = IDEModel.getInstance();
            if (!model.openPreviouslyOpenedProjects) return;

            var cookie:Object = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
            if (!cookie.data["projects"])
            {
                cookie.data["projects"] = [];
            }

            saveProjectItem({name: projectFolderPath, path: projectName}, "name", "path", "projects");
        }

        public static function removeProjectFromOpen(projectFolderPath:String, projectName:String):void
        {
            var model:IDEModel = IDEModel.getInstance();
            if (!model.openPreviouslyOpenedProjects) return;

            removeProjectItem({name: projectFolderPath, path: projectName}, "name", "path", "projects");
        }

        public static function removeCookieByName(cookieName:String):void
        {
            var cookie:Object = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
            if (cookie.data.hasOwnProperty(cookieName))
            {
                delete cookie.data[cookieName];
                cookie.flush();
            }
        }

		private static function saveProjectItem(item:Object, propertyNameKey:String,
                                                propertyNameKeyValue:String, cookieName:String):void
		{
            var cookie:Object = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);
            if (item && item.hasOwnProperty(propertyNameKeyValue) && item.hasOwnProperty(propertyNameKey))
            {
                var hasItemForOpen:Boolean = cookie.data[cookieName].some(
                        function hasSomeItemForOpen(itemForOpen:Object, index:int, arr:Array):Boolean
                        {
                            return itemForOpen.hasOwnProperty(item[propertyNameKey]) && itemForOpen[item[propertyNameKey]] == item[propertyNameKeyValue];
                        });

                if (!hasItemForOpen)
                {
                    var itemForSave:Object = {};
                    itemForSave[item[propertyNameKey]] = item[propertyNameKeyValue];
                    cookie.data[cookieName].push(itemForSave);

                    cookie.flush();
                }
            }
		}

		private static function removeProjectItem(item:Object, propertyNameKey:String,
                                                  propertyNameKeyValue:String, cookieName:String):void
		{
			var cookie:Object = SharedObject.getLocal(SharedObjectConst.MOONSHINE_IDE_PROJECT);

            if (item && item.hasOwnProperty(propertyNameKeyValue) && item.hasOwnProperty(propertyNameKey))
            {
				var data:Object = cookie.data;
                for (var i:int = 0; i < data[cookieName].length; i++)
                {
                    var itemForRemove:Object = data[cookieName][i];
                    if (itemForRemove.hasOwnProperty(item[propertyNameKey]) &&
                            itemForRemove[item[propertyNameKey]] == item[propertyNameKeyValue])
                    {
                        data[cookieName].removeAt(i);
                        cookie.flush();
                        break;
                    }
                }
            }
		}
	}
}