classdef (Sealed) ProcessDependencies < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        dependencies
        
    end
    
    
    properties ( Access = public, Constant )
        
        NAME = 'process_dependency_graph';
        
    end
    
    
    methods ( Access = public )
        
        function obj = ProcessDependencies( dependency_graph_path )
            
            load( fullfile( dependency_graph_path, obj.NAME ), obj.NAME );
            obj.dependencies = eval( eval( 'obj.NAME;' ) ); % HACK to have single name location
            
        end
        
        
        function [ process_order, class_names ] = get_process_order( obj, user_needs )
            %% Visualization
%             gh = plot( ...
%                 pd.requirements_digraph, ...
%                 'edgelabel', 1 : size( edge_names, 1 ) ...
%                 );

            %% NeedsList
            need_count = numel( user_needs );
            search_results = {};
            for i = 1 : need_count

                search_results = union( ...
                    search_results, ...
                    dfsearch( obj.dependencies, user_needs{ i } ) ...
                    );

            end
            needs_graph = subgraph( obj.dependencies, search_results );
%             gh.highlight( ...
%                 needs_graph.Edges.EndNodes( :, 1 ), ...
%                 needs_graph.Edges.EndNodes( :, 2 ), ...
%                 'edgecolor', 'r', ...
%                 'linewidth', 2, ...
%                 'markersize', 2 * gh.MarkerSize, ...
%                 'nodecolor', 'g' ...
%                 );
            ordered_names = toposort( needs_graph );
            process_order = flip( needs_graph.Nodes.Name( ordered_names ) );
            class_names = flip( needs_graph.Nodes.ClassName( ordered_names ) );
            
        end
        
    end
    
end