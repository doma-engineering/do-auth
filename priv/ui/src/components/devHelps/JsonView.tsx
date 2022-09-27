import { useAtomValue } from 'jotai';
import { objectToView } from '../../atoms/devHelpsComponents';

// That is only developers helps component
function JsonView({
    header = 'Object: ',
    className,
}: {
    header?: string;
    className?: string;
}) {
    const obj = useAtomValue(objectToView);
    return (
        <div
            className={`w-[38rem] px-6 py-2 bg-slate-700 rounded shadow-md shadow-slate-900 overflow-hidden ${className}`}
        >
            <h1 className="font-bold">{header}</h1>
            <JsonElements obj={obj} />
        </div>
    );
}
export default JsonView;

const makeSpace = (level: number): string =>
    level > 0 ? `--- ${makeSpace(level - 1)}` : '';

// hard reading recursion displaying any object content
// TODO:
// make sure that they return something if child content is empty string
// make sure that will not broken on arrays,
function JsonElements({ obj, level = 0 }: { obj: any; level?: number }) {
    const findChild = (obj: any, level: number = 0) => {
        if (typeof obj === 'object') {
            let res = [];
            for (var child in obj) {
                if (typeof obj[child] === 'object' && obj[child] !== null) {
                    res.push(
                        <div key={`${level}-${child}-obj_name`}>
                            <span
                                key={`${level}-${child}-obj_name-1`}
                                className="text-blue-500"
                            >
                                {makeSpace(level)}
                            </span>{' '}
                            <span
                                key={`${level}-${child}-obj_name-2`}
                                className="text-orange-300"
                            >
                                {child}
                            </span>
                            :
                            {obj[child].length === 0 ? (
                                <span
                                    key={`${level}-${child}-obj_name-3`}
                                    className="text-orange-700"
                                >
                                    {' '}
                                    empty
                                </span>
                            ) : (
                                <div key={`${level}-${child}-obj_body`}>
                                    {findChild(obj[child], level + 1)}
                                </div>
                            )}
                        </div>
                    );
                } else {
                    res.push(
                        <div key={`${level}-${child}-elem`}>
                            <span
                                key={`${level}-${child}-elem-1`}
                                className="text-blue-500"
                            >
                                {makeSpace(level)}
                            </span>
                            <span
                                key={`${level}-${child}-elem-2`}
                                className="text-orange-300"
                            >
                                {child}
                            </span>
                            :
                            <span
                                key={`${level}-${child}-elem-3`}
                                className="text-blue-200"
                            >
                                {' '}
                                {typeof obj[child] === 'boolean'
                                    ? obj[child]
                                        ? 'true'
                                        : 'false'
                                    : obj[child]}
                            </span>
                        </div>
                    );
                }
            }
            return res;
        } else
            return [
                <div>
                    <span className="text-blue-500">{makeSpace(level)}</span>
                    <span
                        key={`${level}-${obj}-elem-3`}
                        className="text-blue-200"
                    >
                        {' '}
                        {obj}
                    </span>
                </div>,
            ];
    };
    return <div>{findChild(obj, level)}</div>;
}
