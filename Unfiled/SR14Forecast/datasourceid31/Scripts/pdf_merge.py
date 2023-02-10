import glob
from PyPDF2 import PdfFileMerger


def merger(output_path, input_paths):
    pdf_merger = PdfFileMerger()
    file_handles = []

    for path in input_paths:
        pdf_merger.append(path)

    with open(output_path, 'wb') as fileobj:
        pdf_merger.write(fileobj)


if __name__ == '__main__':
    paths = glob.glob('C:\\Users\\aku\\Documents\\QA\\Estimates\\PowerBI\GQ pdf\\*.pdf')
    paths.sort()
    merger('C:\\Users\\aku\\Documents\\QA\\Estimates\\PowerBI\\GQ_outliers_across_vintage.pdf', paths)